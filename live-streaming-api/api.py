from botocore.vendored import requests
import boto3
import json
import string
import random
import uuid
import time
import os
import datetime
import decimal
import re
import traceback


# ENV
dynamodb_table = os.environ["DYNAMODB_TABLE"]
input_security_groups = ["893667"]
medialive_role_arn = os.environ["MEDIALIVE_ROLE_ARN"]
archive_bucket = os.environ["ARCHIVE_BUCKET"]
cloudfront_distribution_id = ""#? os.environ["CLOUDFRONT_DISTRIBUTION_ID"]
resolutions = [1080, 720, 540, 360]

default_segment_lenth = 300
default_startover_window_seconds = 43200
default_key_rotation_interval = 60


class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, decimal.Decimal):
            if abs(o) % 1 > 0:
                return float(o)
            else:
                return int(o)
        return super(DecimalEncoder, self).default(o)

# GET /streams


def get_streams(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dynamodb_table)

    try:
        response = table.scan()
        result = {
            "statusCode": 200,
            "body": json.dumps(response['Items'], indent=4, cls=DecimalEncoder),
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    except Exception as ex:
        print(ex)
        result = {
            'statusCode': 501,
            'body': {"Exception": str(ex)},
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    return result


# GET /streams/{id}
def get_stream(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dynamodb_table)
    stream_id = event['pathParameters']['id']

    try:
        response = table.get_item(
            Key={
                'id': stream_id,
            }
        )
        result = {
            "statusCode": 200,
            "body": json.dumps(response['Item'], indent=4, cls=DecimalEncoder),
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    except Exception as ex:
        print(ex)
        result = {
            'statusCode': 501,
            'body': {"Exception": str(ex)},
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    return result

def delete_cloudfront_distriburion_origin(stream_id):
    client = boto3.client("cloudfront")
    config = client.get_distribution_config(
        Id=cloudfront_distribution_id
    )

    print(config)

    for i, elem in enumerate(config["DistributionConfig"]["CacheBehaviors"]["Items"]):
        if elem["TargetOriginId"] == stream_id:
            config["DistributionConfig"]["CacheBehaviors"]["Items"].pop(i)
            config["DistributionConfig"]["CacheBehaviors"]["Quantity"] -= 1
            break

    for i, elem in enumerate(config["DistributionConfig"]["Origins"]["Items"]):
        if elem["Id"] == stream_id:
            config["DistributionConfig"]["Origins"]["Items"].pop(i)
            config["DistributionConfig"]["Origins"]["Quantity"] -= 1
            break

    print (config)

    response = client.update_distribution(
        Id=cloudfront_distribution_id,
        DistributionConfig=config["DistributionConfig"],
        IfMatch=config["ResponseMetadata"]["HTTPHeaders"]["etag"]
    )


def set_cloudfront_distribution_origin(viewer_endpoint, stream_id):
    client = boto3.client("cloudfront")
    config = client.get_distribution_config(
        Id=cloudfront_distribution_id
    )

    with open("cloudfront_config.json", "r") as config_base_file:
        config_base = json.load(config_base_file)

    results = re.search(r"https:\/\/(.*?)\/(.*)\/.*", viewer_endpoint)
    
    domain_name = results.group(1)
    path_pattern = f"{results.group(2)}/*"

    config_base["Origin"]["DomainName"] = domain_name
    config_base["Origin"]["Id"] = stream_id
    config_base["CacheBehavior"]["TargetOriginId"] = stream_id
    config_base["CacheBehavior"]["PathPattern"] = path_pattern

    config["DistributionConfig"]["Origins"]["Items"].append(config_base["Origin"])
    config["DistributionConfig"]["Origins"]["Quantity"] += 1
    if "Items" not in config["DistributionConfig"]["CacheBehaviors"]:
        config["DistributionConfig"]["CacheBehaviors"]["Items"] = [config_base["CacheBehavior"]]
    else:
        config["DistributionConfig"]["CacheBehaviors"]["Items"].append(config_base["CacheBehavior"])
    config["DistributionConfig"]["CacheBehaviors"]["Quantity"] += 1

    response = client.update_distribution(
        Id=cloudfront_distribution_id,
        DistributionConfig=config["DistributionConfig"],
        IfMatch=config["ResponseMetadata"]["HTTPHeaders"]["etag"]
    )


# POST /streams/{id}/split
def split_stream(event, context):
    dynamodb = boto3.resource('dynamodb')
    s3 = boto3.client('s3', region_name="us-west-2")
    s3_resource = boto3.resource("s3")
    data = json.loads(event["body"])
    table = dynamodb.Table(dynamodb_table)
    stream_id = event['pathParameters']['id']
    session_id = data["session_id"]

    header = "#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:-1\n#EXT-X-MEDIA-SEQUENCE:1\n#EXT-X-PLAYLIST-TYPE:VOD"

    try:
        response = table.get_item(
            Key={
                'id': stream_id,
            }
        )

        channel_id = response['Item']['live_channel_id']
        storage_path = response['Item']['archives_path'][session_id]
        segment_length = int(response['Item']['segment_length'])

        result_re = re.search(r"s3:\/\/(.*?)\/(.*)", storage_path)
        bucket_name = result_re.group(1)
        key_path = result_re.group(2)

        index_number = 0

        name_modifier = data["name_modifier"] if "name_modifier" in data else uuid.uuid4().hex

        index_list = []

        for split in data["timestamp_list"]:
            start_number = int(split["start"]) / segment_length
            end_number = int(split["end"]) / segment_length

            index_content = header

            paginator = s3.get_paginator('list_objects_v2')
            response_iterator = paginator.paginate(
                Bucket=bucket_name,
                Prefix=key_path
            )

            print (start_number, int(split["start"]), end_number, int(split["end"]), segment_length)

            for response in response_iterator:
                for segment in response['Contents']:
                    segment_name = segment['Key'][len(key_path):]
                    if segment_name[-2:] == "ts":
                        segment_number = int(re.search(r".*?\.(.{6})\.ts", segment_name).group(1))
                        if segment_number >= start_number and segment_number <= end_number:
                            index_content += "\n".join(["", f"#EXTINF:{segment_length}", segment_name])

            index_content += "\n#EXT-X-ENDLIST"

            index_name = key_path + f"index_{name_modifier}_{index_number}.m3u8"
            index_output_file = s3_resource.Object(bucket_name, index_name)
            index_output_file.put(Body=bytes(index_content, "utf-8"))

            index_list.append(index_name)

            index_number += 1
        
        result = {
            'statusCode': 200,
            "body": json.dumps({"indexes": index_list}),
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    except Exception as ex:
        print(ex)
        result = {
            'statusCode': 501,
            'body': {"Exception": str(ex)},
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    return result


# POST /streams/{id}/live
def set_stream_cloudfront(event, context):
    mediapackage = boto3.client('mediapackage')
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dynamodb_table)
    stream_id = event['pathParameters']['id']

    try:
        response = table.get_item(
            Key={
                'id': stream_id,
            }
        )

        viewer_endpoint = response["Item"]["viewer_endpoint"]

        #? this is my update
        print(viewer_endpoint)
        # set_cloudfront_distribution_origin(viewer_endpoint, stream_id)

        # cloudfront_associated

        response = table.update_item(
            Key={
                'id': stream_id
            },
            UpdateExpression="set cloudfront_associated = :c",
            ExpressionAttributeValues={
                ':c': True
            },
            ReturnValues="ALL_NEW"
        )
        result = {
            "statusCode": 200,
            "body": json.dumps(response['Attributes'], indent=4, cls=DecimalEncoder),
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    except Exception as ex:
        print(ex)
        traceback.print_exc()
        result = {
            'statusCode': 501,
            'body': {"Exception": str(ex)},
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    return result

# DELETE /streams/{id}/live
def delete_stream_cloudfront(event, context):
    mediapackage = boto3.client('mediapackage')
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dynamodb_table)
    stream_id = event['pathParameters']['id']

    try:
        response = table.get_item(
            Key={
                'id': stream_id,
            }
        )

        #? this is my update
        #delete_cloudfront_distriburion_origin(stream_id)

        response = table.update_item(
            Key={
                'id': stream_id
            },
            UpdateExpression="set cloudfront_associated = :c",
            ExpressionAttributeValues={
                ':c': False
            },
            ReturnValues="ALL_NEW"
        )
        result = {
            "statusCode": 200,
            "body": json.dumps(response['Attributes'], indent=4, cls=DecimalEncoder),
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    except Exception as ex:
        print(ex)
        traceback.print_exc()
        result = {
            'statusCode': 501,
            'body': {"Exception": str(ex)},
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    return result

# POST /streams
def create_stream(event, context):
    mediapackage = boto3.client('mediapackage')
    medialive = boto3.client('medialive')
    dynamodb = boto3.resource('dynamodb')
    ssm = boto3.client('ssm')
    metadata = json.loads(event['body'])
    channel_id = metadata['name']
    table = dynamodb.Table(dynamodb_table)

    stream_id = uuid.uuid4().hex
    passkey = uuid.uuid4().hex
    stream_description = metadata['description']

    segment_length = int(metadata["segment_length"]) if "segment_length" in metadata else default_segment_lenth

    try:
        response = mediapackage.create_channel(
            Id=stream_id,
            Description=stream_description
        )

        print(json.dumps(response))
        attributes = {
            "Url1": response["HlsIngest"]["IngestEndpoints"][0]["Url"],
            "Username1": response["HlsIngest"]["IngestEndpoints"][0]["Username"],
            "Password1": response["HlsIngest"]["IngestEndpoints"][0]["Password"],
            "Url2": response["HlsIngest"]["IngestEndpoints"][1]["Url"],
            "Username2": response["HlsIngest"]["IngestEndpoints"][1]["Username"],
            "Password2": response["HlsIngest"]["IngestEndpoints"][1]["Password"]
        }
        package_channel_id = response['Id']
        response = mediapackage.create_origin_endpoint(
            Id=stream_id,
            Description=stream_description,
            ChannelId=stream_id,
            ManifestName="index",
            StartoverWindowSeconds=default_startover_window_seconds,
            HlsPackage={
                "SegmentDurationSeconds": 6,
                "PlaylistWindowSeconds": 60,
                "PlaylistType": "event",
                "AdMarkers": "SCTE35_ENHANCED",
                "IncludeIframeOnlyStream": True,
                "UseAudioRenditionGroup": False,
                "StreamSelection": {
                    "StreamOrder": "original"
                },
            }
        )
        package_endpoint_id = response['Id']
        print(json.dumps(response))
        viewer_endpoint = response['Url']
        print(viewer_endpoint)
        ssm_name1 = f"/Medialive_api/{str(attributes['Username1'])}"

        response = ssm.put_parameter(
            Name=ssm_name1,
            Value=attributes['Password1'],
            Description=ssm_name1,
            Type='SecureString',
            Overwrite=True
        )

        ssm_name2 = f"/Medialive_api/{str(attributes['Username2'])}"

        response = ssm.put_parameter(
            Name=ssm_name2,
            Value=attributes['Password2'],
            Description=ssm_name2,
            Type='SecureString',
            KeyId='alias/aws/ssm',
            Overwrite=True
        )

        print(json.dumps(response))
        destinations = {
            'p_url': attributes['Url1'], 'p_u': attributes['Username1'], 'p_p': ssm_name1,
            'b_url': attributes['Url2'], 'b_u': attributes['Username2'], 'b_p': ssm_name2
        }

        response = medialive.create_input(
            Name=channel_id,
            Type='RTMP_PUSH',
            Destinations=[
                {
                    'StreamName': "app/{}".format(passkey)
                },
                {
                    'StreamName': "app/{}".format(passkey)
                },
            ],
            InputSecurityGroups=input_security_groups
        )

        live_input_id = response['Input']['Id']
        print(json.dumps(response))
        rtpm1_url = response['Input']['Destinations'][0]['Url']
        rtpm2_url = response['Input']['Destinations'][1]['Url']
        medialive_channel_id, vod_segment_length = create_live_channel(
            stream_id, response['Input']['Id'], channel_id, resolutions, destinations, medialive_role_arn, medialive, segment_length)
        print(json.dumps(medialive_channel_id))

        # set_cloudfront_distribution_origin(viewer_endpoint)

        domain_name = re.search(r"https:\/\/(.*?)\/.*",
                                viewer_endpoint).group(1)
        cloudfront_domain = viewer_endpoint.replace(
            domain_name, "live.frontendmasters.com")

        metadata = json.loads(event['body'])
        metadata['id'] = stream_id
        metadata['rtmp1'] = rtpm1_url
        metadata['rtmp2'] = rtpm2_url
        metadata['rtmp_ivs'] = ""
        metadata["ivs_viewer_endpoint"] = ""
        metadata["ecs_asg_count"] = 0
        metadata['viewer_endpoint'] = viewer_endpoint
        metadata['viewer_endpoint_cloudfront'] = cloudfront_domain
        metadata['last_update'] = str(int(time.time()))
        metadata['last_started'] = None
        metadata['last_stopped'] = None
        metadata['started'] = False
        metadata['live_channel_id'] = medialive_channel_id
        metadata['live_input_id'] = live_input_id
        metadata['package_endpoint_id'] = package_endpoint_id
        metadata['package_channel_id'] = package_channel_id
        metadata['current_session_id'] = None
        metadata['archives_path'] = {}
        metadata['segment_length'] = vod_segment_length
        metadata['ssm_paths'] = [ssm_name1, ssm_name2]
        metadata['cloudfront_associated'] = False
        metadata['key_rotation_interval'] = default_key_rotation_interval
        metadata['startover_window_seconds'] = default_startover_window_seconds

        res = table.put_item(Item=metadata)

        return {
            "statusCode": 200,
            "body": json.dumps(metadata, indent=4),
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    except Exception as ex:
        print(ex)
        result = {
            'statusCode': 501,
            'body': {"Exception": str(ex)},
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    return result


# POST /streams/{id}/start
def start_stream(event, context):
    mediapackage = boto3.client('mediapackage')
    medialive = boto3.client('medialive')
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dynamodb_table)
    if event["body"] is not None:
        metadata = json.loads(event['body'])
    else:
        metadata = []
    stream_id = event['pathParameters']['id']
    session_id = uuid.uuid4().hex

    try:
        response = table.get_item(
            Key={
                'id': stream_id,
            }
        )
        channel_id = response['Item']['live_channel_id']

        key_rotation_interval = response['Item']['key_rotation_interval']
        startover_window_seconds = response['Item']['startover_window_seconds']

        if "key_rotation_interval" in metadata or "startover_window_seconds" in metadata:

            key_rotation_interval = int(metadata["key_rotation_interval"]) if "key_rotation_interval" in metadata else default_key_rotation_interval
            startover_window_seconds = int(metadata["startover_window_seconds"]) if "startover_window_seconds" in metadata else default_startover_window_seconds

            _ = mediapackage.update_origin_endpoint(
            Id=stream_id,
            StartoverWindowSeconds=startover_window_seconds,
            HlsPackage={
                "SegmentDurationSeconds": 6,
                "PlaylistWindowSeconds": 60,
                "PlaylistType": "event",
                "AdMarkers": "SCTE35_ENHANCED",
                "IncludeIframeOnlyStream": True,
                "UseAudioRenditionGroup": False,
                "StreamSelection": {
                    "StreamOrder": "original"
                },
            }
        )

        vod_root = metadata['path'] if 'path' in metadata else generate_archive_path(stream_id)
        vod1 = vod_root + "_1"
        vod2 = vod_root + "_2"

        archives_path = response['Item']['archives_path']
        if type(archives_path) is not dict:
            archives_path = {}
        archives_path[session_id] = vod_root

        config = medialive.describe_channel(
            ChannelId=channel_id
        )

        destinations = config["Destinations"]

        archive_index = 0 if destinations[0]["Id"] == "Archive" else 1

        destinations[archive_index]["Settings"][0]["Url"] = vod1
        destinations[archive_index]["Settings"][1]["Url"] = vod2

        medialive.update_channel(
            ChannelId=channel_id,
            Destinations=destinations
        )

        response = medialive.start_channel(
            ChannelId=channel_id
        )
        response = table.update_item(
            Key={
                'id': stream_id
            },
            UpdateExpression="set started = :s, last_started = :l, archives_path = :a, current_session_id= :c, key_rotation_interval= :k, startover_window_seconds= :w",
            ExpressionAttributeValues={
                ':s': True,
                ':l': str(int(time.time())),
                ':a': archives_path,
                ':c': session_id,
                ':k': key_rotation_interval,
                ':w': startover_window_seconds
            },
            ReturnValues="ALL_NEW"
        )
        result = {
            "statusCode": 200,
            "body": json.dumps(response['Attributes'], indent=4, cls=DecimalEncoder),
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    except Exception as ex:
        print(ex)
        traceback.print_exc()
        result = {
            'statusCode': 501,
            'body': {"Exception": str(ex)},
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    return result


# POST /streams/{id}/stop
def stop_stream(event, context):
    medialive = boto3.client('medialive')
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dynamodb_table)
    stream_id = event['pathParameters']['id']

    try:
        response = table.get_item(
            Key={
                'id': stream_id,
            }
        )
        channel_id = response['Item']['live_channel_id']
        response = medialive.stop_channel(
            ChannelId=channel_id
        )
        response = table.update_item(
            Key={
                'id': stream_id
            },
            UpdateExpression="set started = :s, last_stopped = :l",
            ExpressionAttributeValues={
                ':s': False,
                ':l': str(int(time.time()))
            },
            ReturnValues="ALL_NEW"
        )
        result = {
            "statusCode": 200,
            "body": json.dumps(response['Attributes'], indent=4, cls=DecimalEncoder),
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    except Exception as ex:
        print(ex)
        result = {
            'statusCode': 501,
            'body': {"Exception": str(ex)},
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    return result


# POST /streams/{id}
def update_stream(event, context):
    dynamodb = boto3.resource('dynamodb')
    ssm = boto3.client('ssm')
    table = dynamodb.Table(dynamodb_table)

    try:
        metadata = json.loads(event['body'])
        metadata['last_update'] = str(int(time.time()))
        result = table.put_item(Item=metadata)
        result = {
            'statusCode': 200,
            'body': json.dumps(metadata, indent=4, cls=DecimalEncoder),
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }
    except Exception as ex:
        print(ex)
        result = {
            'statusCode': 501,
            'body': {"Exception": str(ex)},
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }

    return result

def delete_callback(event, context):
    events = boto3.client("events")
    lambda_client = boto3.client("lambda")
    dynamodb = boto3.resource('dynamodb')
    medialive = boto3.client('medialive')
    table = dynamodb.Table(dynamodb_table)

    lambda_callback_name = os.environ["DELETE_CALLBACK_NAME"]

    try:
        arn = event["resources"][0]
        stream_id = re.search(r".*-(.*)", arn).group(1)

        response = table.get_item(
            Key={
                'id': stream_id,
            }
        )

        stream = response['Item']

        response = medialive.delete_input(
            InputId=stream['live_input_id']
        )

        res = events.remove_targets(
            Rule=f"medialive-callback-{stream_id}",
            Ids=["1"]
        )

        res = events.delete_rule(
            Name=f"medialive-callback-{stream_id}"
        )

        res = lambda_client.remove_permission(
            FunctionName=lambda_callback_name,
            StatementId=f"medialive-callback-{stream_id}"
        )

        result = table.delete_item(
            Key={
                'id': stream_id,
            }
        )

        result = {
            'statusCode': 200,
            'body': json.dumps(stream, indent=4, cls=DecimalEncoder),
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }
    except Exception as ex:
        print(ex)
        result = {
            'statusCode': 501,
            'body': {"Exception": str(ex)},
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }
    return result

# DELETE /streams/{id}
def delete_stream(event, context):
    mediapackage = boto3.client('mediapackage')
    medialive = boto3.client('medialive')
    dynamodb = boto3.resource('dynamodb')
    events = boto3.client("events")
    lambda_client = boto3.client("lambda")
    ssm = boto3.client('ssm')
    table = dynamodb.Table(dynamodb_table)
    stream_id = event['pathParameters']['id']

    lambda_callback_arn = os.environ["DELETE_CALLBACK_ARN"]
    # lambda_callback_role_arn = os.environ["DELETE_CALLBACK_ROLE_ARN"]

    try:
        response = table.get_item(
            Key={
                'id': stream_id,
            }
        )

        stream = response['Item']

        response = ssm.delete_parameters(
            Names=stream['ssm_paths']
        )
        reponse = mediapackage.delete_origin_endpoint(
            Id=stream['package_endpoint_id']
        )

        reponse = mediapackage.delete_channel(
            Id=stream['package_channel_id']
        )

        response = medialive.delete_channel(
            ChannelId=stream['live_channel_id']
        )

        res = events.put_rule(
            Name=f"medialive-callback-{stream_id}",
            ScheduleExpression="rate(1 minute)"
        )

        print (res)

        res = lambda_client.add_permission(
            FunctionName=lambda_callback_arn,
            StatementId=f"medialive-callback-{stream_id}",
            Action="lambda:InvokeFunction",
            Principal="events.amazonaws.com",
            SourceArn=res["RuleArn"]
        )

        print (res)

        res = events.put_targets(
            Rule=f"medialive-callback-{stream_id}",
            Targets=[
                {
                    "Id": "1",
                    "Arn": lambda_callback_arn
                }
            ]
        )

        try:
            delete_cloudfront_distriburion_origin(stream_id)
        except Exception as e: 
            print ("Error deleting live cloudfront origin endpoint, ignoring")
            print (e)

        print (res)
        result = {
            'statusCode': 200,
            'body': json.dumps(stream, indent=4, cls=DecimalEncoder),
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }
    except Exception as ex:
        print(ex)
        print (response)
        result = {
            'statusCode': 501,
            'body': {"Exception": str(ex)},
            "headers": {
                "Access-Control-Allow-Origin": "*",
            }
        }
    return result


def create_live_channel(stream_id, input_id, channel_name, layers, destinations, arn, medialive, segment_length):
    vod_root = generate_archive_path(stream_id)
    vod1 = vod_root + "_1"
    vod2 = vod_root + "_2"

    with open('medialive_config.json') as json_data:
        input_settings = json.load(json_data)

    input_settings["InputAttachments"][0]["InputId"] = input_id

    input_settings["Destinations"][0]["Settings"][0]["Url"] = destinations['p_url']
    input_settings["Destinations"][0]["Settings"][0]["Username"] = destinations['p_u']
    input_settings["Destinations"][0]["Settings"][0]["PasswordParam"] = destinations['p_p']
    input_settings["Destinations"][0]["Settings"][1]["Url"] = destinations['b_url']
    input_settings["Destinations"][0]["Settings"][1]["Username"] = destinations['b_u']
    input_settings["Destinations"][0]["Settings"][1]["PasswordParam"] = destinations['b_p']

    input_settings["Destinations"][1]["Settings"][0]["Url"] = vod1
    input_settings["Destinations"][1]["Settings"][1]["Url"] = vod2

    print (segment_length)

    input_settings["EncoderSettings"]["OutputGroups"][1]["OutputGroupSettings"]["ArchiveGroupSettings"]["RolloverInterval"] = segment_length

    print (input_settings)

    vod_segment_length = input_settings["EncoderSettings"]["OutputGroups"][
        1]["OutputGroupSettings"]["ArchiveGroupSettings"]["RolloverInterval"]

    channel_resp = medialive.create_channel(
        Name=channel_name,
        RoleArn=arn,
        InputAttachments=input_settings["InputAttachments"],
        Destinations=input_settings["Destinations"],
        EncoderSettings=input_settings["EncoderSettings"],
        InputSpecification=input_settings["InputSpecification"],
        LogLevel=input_settings["LogLevel"],
        Tags=input_settings["Tags"],
        ChannelClass=input_settings["ChannelClass"]
    )

    print(json.dumps(channel_resp))
    channel_id = channel_resp['Channel']['Id']
    return channel_id, vod_segment_length


def generate_archive_path(stream_id):
    now = datetime.datetime.now()
    date = now.strftime("%Y/%m/%d")
    return "s3://{bucket}/{date}/{stream_id}-{timestamp}/".format(
        bucket=archive_bucket,
        date=date,
        stream_id=stream_id,
        timestamp=int(now.timestamp())
    )
