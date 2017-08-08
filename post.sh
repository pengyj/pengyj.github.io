#! /bin/bash

#得到路径
echo "请输入你需要写入的markdown文件路径..."
read -e path

#存储文件名
fileStp=$(date "+%Y-%m-%d-")
filename=$(echo ${path##*/})
filePath=${fileStp}${filename}

#将markdown第一行文字提取出来做标题
title=$(cat $path | head -1)
title=${title//'#'/''}
title=${title//' '/''}


echo "input category..."
read categories

echo "input tags, split with whitespace..."
read tags

# 把jekyll头写入新文件
inputHead="---\nlayout: post\ntitle: $title\ncategories: $categories\ntags: $tags\n---"
echo -e $inputHead >./_posts/$filePath
# 把原md删除第一行标题写入新文件
sed '1d' $path >>./_posts/$filePath

