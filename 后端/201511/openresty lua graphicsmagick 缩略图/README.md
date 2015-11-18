#openresty lua graphicsmagick 缩略图


## 场景

>常常有这样的情况：产品通常会希望系统中的某些地方可以显示图片的缩略图。
之前用java写了一个图像裁剪的服务，但觉得java并不适合图像的处理，质量不怎么样，内存占用还高。
而且因为图片的输出会使用response流，跟系统其它的协议并不一致，其它协议均支持内容协商。
本着java部分专注业务逻辑的原则，决定将这这个服务重新用lua+graphicsmagick重新实现，变成nginx的一个扩展

#规划及思路:

1. 根据一个网址: http://localhost/img_crop_service/{方案1-3}/{width}/{height}/{filename}?url={原图地址}
1. 如：http://localhost/img_crop_service/1/40/30/123.jpg?url=http://img0.bdstatic.com/img/image/26171547af11b48f5a89bc279d9548811426747517.jpg
1. 第一步：将原图地址md5,获取这个图的保存路径为：md5(url)前三位/md5(url)次三位/md5
1. 第二步：检查要生成的目标小图在不在，存在redirect到处理结果路径：原图本地路径_{width}x{height}_m{方案}
1. 第三步：如果第二步中不在，检查原图在不在，先下载并保存
1. 第四步：根据方案生成小图，重新按第二步的方案处理。


#几个注意事项

1. url对应到文件的算法
1. 如何从img_crop_service 中调用 img_service
1. 更多的裁剪模式支持参考graphicsmagick的api进行扩展
1. 可以写个脚本删除多少天以内没有访问过的冷数据

```lua


-- 写入文件
local function writefile(filename, data)
    local wfile=io.open(filename, "w") --写入文件(w覆盖)
    assert(wfile)  --打开时验证是否出错      
    wfile:write(data)  --写入传入的内容
    wfile:close()  --调用结束后记得关闭
end

-- 检测路径是否目录
local function is_dir(sPath)
    if type(sPath) ~= "string" then return false end

    local response = os.execute( "cd " .. sPath )
    if response == 0 then
        return true
    end
    return false
end

-- 检测文件是否存在
local file_exists = function(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end


-- 第一步：准备阶段
local model = ngx.var.model;
local width = ngx.var.width;
local height = ngx.var.height;
local img_root = ngx.var.img_root;
local url = ngx.var.url;
--根据url推算文件应该存放在哪个位置,存放规则:md5(url)前三位/md5(url)次三位/md5
local md5 = ngx.md5(url);
local first = string.sub(md5, 0, 3);
local second = string.sub(md5, 4, 6);
local dir = img_root.."/"..first.."/"..second.."/";
local ori_file_path = dir..md5;
local min_file_name = md5.."_"..width.."x"..height.."_"..model;
local min_file_path = dir..min_file_name;

ngx.header["mmm"] = model;


-- --第二步：是否已经生成过了

if file_exists(min_file_path) then
    ngx.header["min_file_path"] = min_file_path;
    -- /imgservice/603/9eb/6039ebd7e2f78f755cccf47907174c00_100x100_m1
    local redirect = "/img_service/"..first.."/"..second.."/"..min_file_name;
    local res = ngx.location.capture(redirect)
    if res.status == 200 then
      ngx.print(res.body)
    end
end


-- --第三步：原图在不在，不在下载

if not file_exists(ori_file_path) then
    ngx.header["ori_file_path"] = ori_file_path;
    local http = require("resty.http")
    --创建http客户端实例
    local httpc = http.new()

    local resp, err = httpc:request_uri(url, {
        method = "GET",
        --path = "",
        headers = {
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36"
        }
    })

    if not resp then
        ngx.say("request error :", err)
        return ngx.exit(500)
    end

    if not is_dir(dir) then
        os.execute("mkdir -p " .. dir)
        ngx.header["mkdir"] = dir;
    end
    --响应体
    --ngx.header["writefile"] = "true";
    ngx.header["ori_file_path"] = ori_file_path;
    writefile(ori_file_path, resp.body)
    httpc:close()
end

-- --第四步：生成小图

if not file_exists(ori_file_path) then
    return ngx.exit(500)
else

-- m1 定宽等比绽放，小于宽度不处理
-- gm convert t.jpg -resize "300x100000>" -quality 30 output_1.jpg

-- m2 等比绽放，裁剪，比较适合头象，logo之类的需要固定大小的展示
-- gm convert sh.jpg -thumbnail "100x100^" -gravity center -extent 100x100 -quality 30 output_3.jpg

-- m3 等比绽放，不足会产生白边
-- gm convert sh.jpg -thumbnail "100x100" -gravity center -extent 100x100 -quality 30 output_3.jpg

    local command = "";
    if (model == "m1") then
        command = "gm convert " .. ori_file_path  
        .. " -resize \"" .. width .."x100000>\""
        .. " -background \"#fafafa\" "
        .. " -quality 90 "
        .. min_file_path;
    elseif (model == "m2") then
        local size = width.."x"..height.."^";
        command = "gm convert " .. ori_file_path  
        .. " -thumbnail \"" .. size .."^\" "
        .. " -gravity center "
        .. " -background \"#fafafa\" "
        .. " -extent " .. size
        .. " -quality 90 "
        .. min_file_path;
    elseif (model == "m3") then
        local size = width.."x"..height;
        command = "gm convert " .. ori_file_path  
        .. " -thumbnail " .. size .." "
        .. " -gravity center "
        .. " -background \"#fafafa\" "
        .. " -extent " .. size
        .. " -quality 90 "
        .. min_file_path;
    end
    ngx.header.command = command;
    os.execute(command);  
end


if file_exists(min_file_path) then
    -- /imgservice/603/9eb/6039ebd7e2f78f755cccf47907174c00_100x100_m1
    local redirect = "/img_service/"..first.."/"..second.."/"..min_file_name;
    ngx.header["min_file_path"] = min_file_path;
    ngx.header["redirect"] = redirect;
    local res = ngx.location.capture(redirect)
    if res.status == 200 then
      ngx.print(res.body)
    end
    ngx.exit(200)
else
    ngx.exit(404)
end

```

nginx的配置

```conf
location /img_service {
        default_type text/plain;
        root /Volumes/data/workspace/lua_service;
}

location /img_crop_service {
    resolver 223.5.5.5;
    default_type text/plain;
    alias /Volumes/data/workspace/lua_service/img_service;
    set $img_root "/Volumes/data/workspace/lua_service/img_service";
    if ($uri ~ "/img_crop_service/(m[1-3])/([0-9]+)/([0-9]+)/(.*)") {
        set $model $1;
        set $width $2;
        set $height $3;
        set $dir "$img_root";
        set $file "$dir$4";
        set $req_args "$args";
    }
    if ($args ~ "url=(.*)") {
        set $url $1;
    }
    #if (!-f $file) {
        content_by_lua_file "/Volumes/data/workspace/lua_service/img_service/http_proxy.lua";
    #}
}
```

##使用示例及测试

效果01

![ls 效果图](https://github.com/lenxeon/notes/blob/master/后端/201511/openresty lua graphicsmagick 缩略图/样例01.png)

效果02

![ls 效果图](https://github.com/lenxeon/notes/blob/master/后端/201511/openresty lua graphicsmagick 缩略图/样例02.png)

存储路径样例，可以写个脚本删除多少天以内没有访问过的冷数据

![ls 效果图](https://github.com/lenxeon/notes/blob/master/后端/201511/openresty lua graphicsmagick 缩略图/存储结果.png)
