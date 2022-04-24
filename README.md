# 使用Docker

## 遇到的几个问题以及解决方法

### docker用户权限问题

如果你在主机上不是root用户，那么使用官方的教程(`./run-docker sh -- ./build --download-dependencies qemu-buildroot`)很可能会遇到下面的问题：

```bash
git config --global --add safe.directory xxx
```

这是因为构建的docker使用的root用户，而从主机映射过去的不是root用户（即你在服务器上的id不是0），这就出现了git抱怨当前文件夹的所有者和正在操作的用户不是一个人。

解决办法：

1. 使用下面命令创建docker image
   1. 修改了`run-docker`脚本，以及`Dockerfile`，细节查看`create_docker_iamges`文件夹
   
   2. 具体思路是：构建镜像的时候会创建一个dev用户，而实例化这个镜像的时候，会传进去当前用户的uid和gid，然后容器有一个启动脚本会给dev用户赋予这个uid和gid
   
      ![image-20220423155738497](https://image.beenli.cn/image-20220423155738497.png?imageslim)
   
   3. 在操作系统看起来，docker发出的系统调用就像是你在主机的用户发出的操作。

```
./run-docker create (构建的image名称为lkmc)
```

​	如果想要构建root用户的镜像，需要使用 `./run-docker --root create `(构建的image名称为lkmc-root)

2. 或者直接关闭这个检查

   ```bash
   /run-docker --root sh -- git config --global --add safe.directory '*'
   ```

   ![image-20220423182151059](https://image.beenli.cn/image-20220423182151059.png?imageslim)

   > [我没有意识到通配符仅在 git v2.35.1 及更高版本中可用。Ubuntu 20.04 附带 v2.25.1。](https://stackoverflow.com/questions/71849415/i-cannot-add-the-parent-directory-to-safe-directory-in-git)
   >
   > ```bash
   > sudo add-apt-repository ppa:git-core/ppa
   > 
   > sudo apt update
   > 
   > sudo apt install git
   > ```
   >
   > ![image-20220423184048245](https://image.beenli.cn/image-20220423184048245.png?imageslim)
   >
   > ![image-20220423185051018](https://image.beenli.cn/image-20220423185051018.png?imageslim)

### build脚本写系统文件权限问题

具体见build 553行，把写入的目的文件"/etc/apt/source.list"，改到"test_apt.list"，

然后调用sudo去执行这个操作（因为在构建镜像的时候已经赋予了dev sudo的权限）

```python
sources_path = os.path.join('/etc', 'apt', 'sources.list')
with open(sources_path, 'r') as f:
    sources_txt = f.read()
    sources_txt = re.sub('^# deb-src ', 'deb-src ', sources_txt, flags=re.MULTILINE)
    m = os.system('touch test_apt.list')
    with open("test_apt.list", 'w') as f:
        f.write(sources_txt)
    p = os.system('sudo mv test_apt.list %s' % sources_path)
```

### ln -sf ../configure xxx(configure找不到)

![image-20220423215651034](https://image.beenli.cn/image-20220423215651034.png?imageslim)

这个还没找到解决办法

### add-apt-repository不能使用

```
 apt-get install software-properties-common
```

### 不能import同目录的python文件

1. 保证文件以py结尾(可以试试，也不一定需要，有点玄学)

2. 如果不行，试试加入

   ```python
   import os, sys
   sys.path.append(os.path.dirname(os.path.realpath(__file__)))
   # why not include the PYTHONPATH?
   ```

## 脚本说明

1. 构建镜像

   ```bash
   ./run-docker [--root] [--image_name xxx] build
   ```

   1. 如果不提供--root，则构建dev用户的镜像
   2. 如果不提供image_name，则默认为`test_image`

2. 创建容器

   ```bash
   ./run-docker [--root] --image_name xxx --container_name xxx --host_dir xxx --repo_name xxx create
   ```

   1. 如果不使用--root，则挂载镜像的时候，挂载到容器里面的/root/repo_name，否则挂载到/home/dev/repo_name
   2. repo_name 默认为test_dir
   3. image_name默认为test_image
   4. container_name 为test_container
   5. **脚本修改后从命令行读入http_proxy，直接传给容器。**

3. 运行容器

   ```bash
   ./run-docker --container_name xxx  [--root] sh  [shell command]
   ```

   1. 如果不适用--root，则使用dev登录到环境中
   2. 容器名字跟上面创建容器的名字相同
   3. 如果不给shell command，则直接进入到shell中，否则执行完命令退出。

4. 给apt和pip换源

   ```bash
   ./run-docker --container_name xxx  [--root] sh
   ```

   1. apt
      1. [阿里云](https://developer.aliyun.com/mirror/ubuntu?spm=a2c6h.13651102.0.0.3e221b117brkMQ)
      2. [清华](https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/)
   2. pip（pip config set global.index-url https://pypi.douban.com/simple）
      1. 阿里云：http://mirrors.aliyun.com/pypi/simple/ 
      2. 豆瓣(douban) http://pypi.douban.com/simple/ 
      3. 清华大学 https://pypi.tuna.tsinghua.edu.cn/simple/ 

5. 构建gem5-buildroot

```
./run-docker --root --container_name xxx sh -- ./build --download-dependencies gem5-buildroot
```

