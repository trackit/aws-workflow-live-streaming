# FrontMaster Live Stream

## Infrastructure

![Infrastructure](.documentation/livestream.png)

## Deployment

## Workflow

### 1. Create a stream

To create a stream, you will have to make a `POST` request to `/streams` with a body containing a name (and an optional description).

This endpoint will return all the information for this new stream, such as the stream ID, details you will need to configure your streaming software or also the output URL.

### 2. Start the stream

With a `POST` request to `/streams/{stream_id}/start`, the API will start the MediaLive Channel and you will be able to send data with your streaming software.

### 3. Select the stream for the live Cloudfront distributio

With a `POST` request to `/streams/{stream_id}/live`, the API will associate the stream with the "live" Cloudfront distribution, setting the domain `live.frontendmasters.com` to the mediapackage url for this stream. 

### 4. Stream your content

The `rtmp1` value from stream details contains two information needed to configure your streaming software: `rtmp://IP_ADDRESS:PORT/STREAMING_KEY`

Example with OBS:

![OBS Setup](.documentation/obs_setup.png)

Server: `rtmp://IP_ADDRESS:PORT/`

Stream Key: `STREAMING_KEY`

### 5. Stop the stream

With a `POST` request to `/streams/{stream_id}/stop`, the API will stop the MediaLive Channel.

### 6. Split the record of the stream

You can send information on how to split the record of a stream with a `POST` request to `/streams/{stream_id}/split`. The API will generate for each requested section a dedicated M3U8 file which will then automatically be transcoded to a mp4 file.

The output bucket for this file is defined in the variable `fem_workshop_output_bucket` in the main module. It is currently `fem-workshops-out`.
The path mirrors the path of the `.ts` files that are saved by Medialive.

The output files will be named `index_{pos_in_list}.mp4`. 

You will need to pass a list of objects containing the start and finish timestamps of each section. The timestamps are in seconds.

You will also need to pass the `session_id` parameter for the stream you want to select (since a channel can be reused for multiple streams).

The `session_id` is the key of the `archives_path` map corresponding to the path you want to use. 

Example of the body:
````json
{
    "timestamp_list": [
        {
            "start": 123,
            "end": 456
        },
        {
            "start": 789,
            "end": 123456
        },
        {
            "start": 123456,
            "end": 456789
        }
    ],
    "session_id": "1234567890ABCDEF"
}
````
---

## Note the DynamoDB scheme was updated for the following routes, so you'll have to create new streams to use them

---

### 7. Stream a Chime Meeting to Medialive

To start the streaming of Chime meeting to media live, you need to have the following things : 

- A started Medialive channel and its `{stream_id}`
- A chime meeting and its url `{chime_url}`. An example url is `https://j7zzx3mcs9.execute-api.us-east-1.amazonaws.com/Prod/v2?m=mjg-test-connector-meeting`

You will then need to make a `POST` request to the `/streams/{stream_id}/chime_start` with the following body : 

```json
{
    "chime_url": "{chime_url}&broadcast=true"
}
```

Note that you have to append the `&broadcast=true` string to the Chime url.

It will then spin up a new instance in the ECS cluster, and start a task for streaming. Note that it can take up to ten minutes to start the streaming.

Note also that currently you can't have more than one connector running at a time.

### 8. Stream a Chime Meeting to IVS 

The route is identical to the one to start the chime connector to medialive, except its endpoint is `/streams/{stream_id}/ivs_start`.

It also returns two new arguments in the body response : 

- `ivs_viewer_endpoint` : Url for the m3u8 manifest file of the IVS stream.
- `rtmp_ivs` : RTMP endpoint for the IVS service, in case you want to directly send video to IVS.

### 9. Stop streaming the Chime Meeting to Medialive

Send a `POST` request to `/streams/{stream_id}/chime_stop` with `{stream_id}` as the Medialive channel id.

### 10. Stop streaming the Chime Meeting to IVS

Send the same request as for Medialive, but on the `/streams/{tream_id}/ivs_stop` endpoint.

## API Documentation

### GET /streams

Returns list of available streams

Body:
````json
No body required
````

Response:

````json
[
    {
        "name": "stream_name",
        "description": "Stream description",
        "id": "1234567890ABCDEF",
        "rtmp1": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
        "rtmp2": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
        "viewer_endpoint": "http://url_for_output",
        "archives_path": {
            "1234567890ABCDEF": "s3://bucket/path/to/archive"
        },
        "last_update": "1234567890",
        "last_started": null,
        "last_stopped": null,
        "started": true,
        "current_session_id": null,
        "live_channel_id": "1234567890ABCDEF",
        "live_input_id": "1234567890ABCDEF",
        "package_endpoint_id": "1234567890ABCDEF",
        "package_channel_id": "1234567890ABCDEF"
    },
    {
        "name": "another_stream_name",
        "description": "Stream description again",
        "id": "1234567890ABCDEF",
        "rtmp1": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
        "rtmp2": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
        "viewer_endpoint": "http://url_for_output",
        "archives_path": {},
        "last_update": "1234567890",
        "last_started": null,
        "last_stopped": null,
        "started": false,
        "current_session_id": null,
        "live_channel_id": "1234567890ABCDEF",
        "live_input_id": "1234567890ABCDEF",
        "package_endpoint_id": "1234567890ABCDEF",
        "package_channel_id": "1234567890ABCDEF"
    }
]
````

### GET /streams/{id}

Returns details for requested stream

Body:
````json
No body required
````

Response:

````json
{
    "name": "stream_name",
    "description": "Stream description",
    "id": "1234567890ABCDEF",
    "rtmp1": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "rtmp2": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "viewer_endpoint": "http://url_for_output",
    "archives_path": {
        "1234567890ABCDEF": "s3://bucket/path/to/archive"
    },
    "last_update": "1234567890",
    "last_started": null,
    "last_stopped": null,
    "started": false,
    "current_session_id": null,
    "live_channel_id": "1234567890ABCDEF",
    "live_input_id": "1234567890ABCDEF",
    "package_endpoint_id": "1234567890ABCDEF",
    "package_channel_id": "1234567890ABCDEF"
}
````

### POST /streams

Creates a stream and returns its details

Body:
````json
{
    "name": "my_stream",
    "description": "This is a stream",
    "segment_length": 123
}
````

`segment_length` is an optional argument which allow you to control the size of the segment files saved to S3, in seconds. If no value is provided, the default of 300 seconds is used.

Response:

````json
{
    "name": "my_stream",
    "description": "This is a stream",
    "id": "1234567890ABCDEF",
    "rtmp1": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "rtmp2": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "viewer_endpoint": "http://url_for_output",
    "archives_path": {},
    "last_update": "1234567890",
    "last_started": null,
    "last_stopped": null,
    "started": false,
    "current_session_id": null,
    "live_channel_id": "1234567890ABCDEF",
    "live_input_id": "1234567890ABCDEF",
    "package_endpoint_id": "1234567890ABCDEF",
    "package_channel_id": "1234567890ABCDEF"
}
````

### POST /streams/{id}

Updates requested stream details

Body:
````json
{
    "name": "my_stream",
    "description": "This is a stream with MediaLive",
    "id": "1234567890ABCDEF",
    "rtmp1": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "rtmp2": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "viewer_endpoint": "http://url_for_output",
    "archives_path": {},
    "last_update": "1234567890",
    "last_started": null,
    "last_stopped": null,
    "started": false,
    "current_session_id": null,
    "live_channel_id": "1234567890ABCDEF",
    "live_input_id": "1234567890ABCDEF",
    "package_endpoint_id": "1234567890ABCDEF",
    "package_channel_id": "1234567890ABCDEF"
}
````

Response:

````json
{
    "name": "my_stream",
    "description": "This is a stream with MediaLive",
    "id": "1234567890ABCDEF",
    "rtmp1": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "rtmp2": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "viewer_endpoint": "http://url_for_output",
    "archives_path": {},
    "last_update": "1234567890",
    "last_started": null,
    "last_stopped": null,
    "started": false,
    "live_channel_id": "1234567890ABCDEF",
    "live_input_id": "1234567890ABCDEF",
    "package_endpoint_id": "1234567890ABCDEF",
    "package_channel_id": "1234567890ABCDEF"
}
````

### POST /streams/{id}/start

Starts requested stream

Body:
````json
{
    "path": "optional_path",
    "startover_window_seconds": 123,
    "key_rotation_interval": 123
}
````
N.B.: `path` is not mandatory, if not provided a path will be generated with the following format: `s3://$archive_bucket/$year/$month/$day/$stream_id-$timestamp`.

Arguments `startover_window_seconds` and `key_rotation_interval` are not mendatory, and if not set their default values will be used, 3600 and 60 respectively. 

Both are in seconds. 

`startover_window_seconds` controlls the amount of time that a stream can be rewound to.
`key_rotation_interval` controlls how often the encryption key will be rotated when streaming.

Response:

````json
{
    "name": "my_stream",
    "description": "This is a stream",
    "id": "1234567890ABCDEF",
    "rtmp1": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "rtmp2": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "viewer_endpoint": "http://url_for_output",
    "archives_path": {
        "1234567890ABCDEF": "s3://bucket/path/to/archive"
    },
    "last_update": "1234567890",
    "last_started": "1234567890",
    "last_stopped": null,
    "started": true,
    "current_session_id": "1234567890ABCDEF",
    "live_channel_id": "1234567890ABCDEF",
    "live_input_id": "1234567890ABCDEF",
    "package_endpoint_id": "1234567890ABCDEF",
    "package_channel_id": "1234567890ABCDEF"
}
````

### POST /streams/{id}/live

Associates stream with `live.frontendmasters.com` Cloudfront distribution.

You can associate an arbitrary number of streams with the live Cloudfront distribution

Body:
````json
No body required
````

Response:
````
No response
````

### DELETE /streams/{id}/live

Dissociates the stream with `live.frontendmasters.com` Cloudfront distribution.

Note that when calling DELETE on `/streams/{id}` it will automatically dissociate the endpoint from the live endpoint. 

Body:
````json
No body required
````

Response:
````
No response
````

### POST /streams/{id}/stop

Stops requested stream

Body:
````json
No body required
````

Response:

````json
{
    "name": "my_stream",
    "description": "This is a stream",
    "id": "1234567890ABCDEF",
    "rtmp1": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "rtmp2": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "viewer_endpoint": "http://url_for_output",
    "archives_path": {
        "1234567890ABCDEF": "s3://bucket/path/to/archive"
    },
    "last_update": "1234567890",
    "last_started": "1234567890",
    "last_stopped": "1234567890",
    "started": true,
    "current_session_id": "1234567890ABCDEF",
    "live_channel_id": "1234567890ABCDEF",
    "live_input_id": "1234567890ABCDEF",
    "package_endpoint_id": "1234567890ABCDEF",
    "package_channel_id": "1234567890ABCDEF"
}
````

### POST /streams/{id}/chime_start

Starts the Chime meeting connector

Body:
````json
{
    "chime_url": "{chime_url}&broadcast=true"
}
````

With `chime_url` as the chime meeting url. Note that you need to append the `&broadcast=true` to the url, and you need to have the `/v2/` version of the frontend.

An working example url would be : 

```
https://j7zzx3mcs9.execute-api.us-east-1.amazonaws.com/Prod/v2?m=mjg-test-connector-meeting&broadcast=true
```

Response:

````json
{
    "name": "my_stream",
    "description": "This is a stream",
    "id": "1234567890ABCDEF",
    "rtmp1": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "rtmp2": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "viewer_endpoint": "http://url_for_output",
    "archives_path": {
        "1234567890ABCDEF": "s3://bucket/path/to/archive"
    },
    "last_update": "1234567890",
    "last_started": "1234567890",
    "last_stopped": "1234567890",
    "started": true,
    "current_session_id": "1234567890ABCDEF",
    "live_channel_id": "1234567890ABCDEF",
    "live_input_id": "1234567890ABCDEF",
    "package_endpoint_id": "1234567890ABCDEF",
    "package_channel_id": "1234567890ABCDEF"
}
````

### POST /streams/{id}/chime_stop

Stops the Chime sdk connector tasks, and removes the instance from the ecs cluster.

Body:
````json
No body required
````

Response:

````json
{
    "name": "my_stream",
    "description": "This is a stream",
    "id": "1234567890ABCDEF",
    "rtmp1": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "rtmp2": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "viewer_endpoint": "http://url_for_output",
    "archives_path": {
        "1234567890ABCDEF": "s3://bucket/path/to/archive"
    },
    "last_update": "1234567890",
    "last_started": "1234567890",
    "last_stopped": "1234567890",
    "started": true,
    "current_session_id": "1234567890ABCDEF",
    "live_channel_id": "1234567890ABCDEF",
    "live_input_id": "1234567890ABCDEF",
    "package_endpoint_id": "1234567890ABCDEF",
    "package_channel_id": "1234567890ABCDEF"
}
````

### POST /streams/{id}/split

Split archive for requested stream

Body:
````json
{
    "timestamp_list": [
        {
            "start": 123,
            "end": 456
        },
        {
            "start": 789,
            "end": 123456
        },
        {
            "start": 123456,
            "end": 456789
        }
    ],
    "session_id": "1234567890ABCDEF",
    "name_modifier": "test"
}
````

Response:

````json
No response
````

`name_modifier` is an optional argument that adds a modfier to the name of the generated indexes, to differenciate between multiple calls of this endpoint. 
If it is not specified, a UUID will be generated and used.

### DELETE /streams/{id}

Deletes requested stream and returns its details

Body:
````json
No body required
````

Response:

````json
{
    "name": "my_stream",
    "description": "This is a stream",
    "id": "1234567890ABCDEF",
    "rtmp1": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "rtmp2": "rtmp://IP_ADDRESS:PORT/STREAMING_KEY",
    "viewer_endpoint": "http://url_for_output",
    "archives_path": {
        "1234567890ABCDEF": "s3://bucket/path/to/archive"
    },
    "last_update": "1234567890",
    "last_started": "1234567890",
    "last_stopped": "1234567890",
    "started": true,
    "current_session_id": "1234567890ABCDEF",
    "live_channel_id": "1234567890ABCDEF",
    "live_input_id": "1234567890ABCDEF",
    "package_endpoint_id": "1234567890ABCDEF",
    "package_channel_id": "1234567890ABCDEF"
}
````
