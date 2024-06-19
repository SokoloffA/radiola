ICY
===

The ICY name can both mean the source and client protocol. Here we assume it means the client protocol. ICY is built on HTTP but early versions might report ICY instead of HTTP. This is now deprecated and should not be used as it might break HTML5 compatibility.

Server headers
--------------

* icy-br: send the bitrate in kilobits per second
* icy-genre: sends the genre
* icy-name: sends the stream's name
* icy-url: is the URL of the radio station
* icy-pub: can be 1 or 0 to tell if it is listed or not

* icy-notice1:`<BR>This stream requires <a href="http://www.winamp.com">Winamp</a><BR>`
* icy-notice2:`SHOUTcast DNAS/posix(linux x86) v2.4.7.256<BR>`

These notices are probably still here for legacy reasons or just free advertising. In Cast we left them out and still got no compatibility issues.


Metadata
--------

If the client sends the `Icy-MetaData:1` header this means the client supports ICY-metadata. The server should respond `icy-metaint: 8192`. 8192 is the number of bytes between 2 metadata chunks. It is suggested to use this value as some players might have issues parsing other values. In these chunks `StreamTitle='title of the song';` send the new song title. There also is a `StreamURL` field which should be able to also send album art links or more info. The exact implementation is however unknown.

_RealPlayer (deprecated, but this is Internet Radio) tells it likes ICY metadata but it can't parse it. You should ignore it if a RealMedia client asks._

Read more
---------

http://www.smackfu.com/stuff/programming/shoutcast.html

Trivia
------

ICY stands for I Can Yell. ICYcast was also the name of the "beta" builds of SHOUTcast. There are a few of these still running.

---

_Source: https://cast.readme.io/docs/icy_
