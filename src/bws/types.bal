import ballerina/time;

type ResourceInfo record {
    string mediaType;
    string content;
    int contentLength;
    time:Time lastModifiedTime;
    string eTag;
};
