#!/usr/bin/bash

docker run --name temp-lovr-apps lovr-apps:latest
docker cp temp-lovr-apps:/root/apps/LÖVR-x86_64.AppImage .
docker cp temp-lovr-apps:/root/apps/OverlayTest-x86_64.AppImage .
docker cp temp-lovr-apps:/root/apps/HandVisualizer-x86_64.AppImage .
docker rm temp-lovr-apps
