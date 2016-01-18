cocoa_sina_pics_upload
======================

Bulk ppload pictures to SINA blog picture library.

向SINA图片数据库批量上传图片的步骤：


1. 登录URL
=

URL:
http://photo.blog.sina.com.cn/apis/client/client_login.php

发送Http Get 请求。参数就是用户名和密码以及appname和工具版本号。细节如下图所示。
我们欺骗了服务器，它以为这是一个Microsoft IE 6 发来的请求

![Login](https://github.com/0x7ace80/cocoa_sina_pics_upload/raw/master/001PI1gJty6Fl68elhUba&690.png)

服务器会返回三个重要参数是后面几步都要用到的：
userId:   一串数字，代表用户的ID。对于同一个用户来说每次连接都不变。
token：   一串Hex，用于Login服务器识别本次操作。每次连接都有不同的token。
session:  一串Hex，用于Login服务器和图片服务器上识别本次操作。每次连接都有不同值。

2. 获得“专辑列表”
=

新浪图片允许用户建立不同的“专辑”。上传的时候用户必须指出把图片放到哪个专辑中。
通过向URL

http://photo.blog.sina.com.cn/apis/client/client_get_photoinfo.php

发送Get请求来得到专辑列表。请求的参数就包括了刚才得到的UserID和token。
此次Get方法返回一个XML 格式内容，里面包括用户建立的专辑的ID号和名字。ID号是一串数字用于后面上传图片，名字是给用户看的。在后面专辑ID的参数名是“ctgid” ctg应当是category的缩写我猜。

3. 上传图片数据
=

用户选择专辑之后，开始上传图片数据。采用HTTP标准的上传格式（rfc1867 协议）。在上传时必须按照该协议构造数据包，上传数据才能被服务器接收。稍有差池上传都会失败。新浪要求图片不能大于5M。
通过向URL

http://upload.photo.sina.com.cn/interface/pic_upload.php

发送Post请求上传数据。参数包括了token和Session和包含文件二进制内容的数据包。注意从URL上可以看出和刚才Login的服务器不一样了，这应该是新浪图片专门的服务器。所以要使用Session参数来告诉这个服务器是哪个会话在上传数据。

然后一个大的图片数据包会被切割成小块不断向服务器上传。全部数据上传完毕之后服务器还会返回一个xml格式的内容里面包含了回执字串。（recipeString）。如果上传失败则无法得到回执字串。


4. 回执
=

告诉Login服务器更新上传图片。由于我们是向另外一台服务器上传了图片，原来的Login的服务器并不知道图片是否已经完成上传，所以需要向Login服务器提交刚才从图片服务器那里得到的回执字串。我猜Login服务器通过回执字串从图片服务器提取上传图片并且处理缩略图等等。
采用Post方法向URL

http://photo.blog.sina.com.cn/upload/upload_receive.php

上传回执字串。URL上得参数还包括UserID和token和ctgid和图片的名字，这个名字是用户给出的不是上传时的文件名，还包括其他参数诸如appname和Version之类的。

![Login](https://github.com/0x7ace80/cocoa_sina_pics_upload/raw/master/001PI1gJty6Fl687sJBc3&690.jpg)

这时如果一切顺利服务器返回OK字符串。整个图片上传过程完成，可以在网页上看到新的图片了。
总结起来新浪图片上传流程和平时上衙门办证件的流程挺像：先是拿号（Login），然后到指定窗口填表（选择专辑），然后拿着证明去银行付款（上传图片到图片服务器），之后带着银行收据（回执字串）回去拿证件（更新Login服务器）。
