import ballerina/cache;
import ballerina/file;
import ballerina/io;
import ballerina/crypto;

function loadContent(@tainted cache:Cache contentCache, string webPath, string docRoot) returns @tainted error? {
    check loadFiles(contentCache, webPath, docRoot);
}

function loadFiles(@tainted cache:Cache c, string webPath, string docRoot) returns @tainted error? {
    // get a list of all files in docRoot
    if !file:exists(docRoot) {
        return error("No such file: " + docRoot);
    }
    file:FileInfo[] list = check file:readDir(docRoot);

    // put index content
    string indexContents = list.toString();
    check c.put(webPath, indexContents);
    check c.put(webPath + "/", indexContents);
    
    foreach var f in list {
        string fname = f.getName();
        if f.isDir() {
            check loadFiles(c, webPath + "/" + docRoot, fname);
        } else {
            string key = webPath + "/" + docRoot + "/" + fname;
            ResourceInfo ri = check loadOneFile(f);
            check c.put(key, ri);
        }
    }
}

function loadOneFile(file:FileInfo f) returns @tainted ResourceInfo | error {
    string fname = f.getName();
    io:ReadableByteChannel fc = check io:openReadableFile(fname);
    io:ReadableCharacterChannel cc = new (fc, "UTF-8");
    string content = "";
    while true {
        var gotSome = cc.read(8096);
        if gotSome is string {
            content += gotSome;
        } else {
            break;
        }
    } 
    check cc.close();
    check fc.close();
    return {
        mediaType: getMediaType(fname),
        contentLength: content.length(),
        content: content,
        lastModifiedTime: f.getLastModifiedTime(),
        eTag: generateETag(content)
    };
}

function getMediaType(string filename) returns string {
    int index = filename.lastIndexOf(".") ?: -1;
    if index == -1 {
        return DEFAULT_MEDIA_TYPE;
    }
    string ext = filename.substring(index);
    return MEDIA_TYPES[ext] ?: DEFAULT_MEDIA_TYPE;
}

function generateETag(string content) returns string {
    return crypto:hashSha1(content.toBytes()).toBase64();
}