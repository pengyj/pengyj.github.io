#OCLint深度定制

##Rules原理
OCLint是一个基于规则的工具。Rules是动态库，可以简单实时的加载进正在运行的系统。通过动态加载扩展规则而不修改或重新编译自身。

解析原理通常分为2大类：基于源代码的逐行解析，和基于AST的解析。

源代码解析，可以利用```AbstractSourceCodeReaderRule```。

基于AST的规则解析，OCLint提供2种：AST visitor和AST matcher。

[AST visitor](https://en.wikipedia.org/wiki/Visitor_pattern)是一种基于深度优先的遍历规则。例如一个文件有2个方法，会从第1个方法开始，按顺序访问里面的所有节点，包括类型、参数、操作符、返回值等等。

但是，这个看起来并不直观。所以有了```AST matcher```。
```
ifStmt(hasCondition(binaryOperator(hasOperatorName("&&"))))
```

AST matcher比AST visitor更容易阅读。但是却比它有更多的限制场景、更长的分析时间、和更差的性能表现。所以在使用的时候需要我们考虑权衡到底使用哪一个。

##写Rules
编写一个rule我们需要提供命名和优先级。

优先级有P1､ P2､ P3, 官方的解释是，```the less number has a higher priority```，即数字越小严重程度越高。

所有的规则都是RuleBase的子类，每个```RuleBase```对象都会提供一个```RuleCarrier```, 它会携带```ASTContext```(抽象语法树)和```violation```(违规集)。

ASTContext有所有的节点信息，我们找出特定的节点抛给violation来处理。

由于我们的大多数规则可以重用某些逻辑来使工作更好，所以我们推荐继承我们提供的抽象类。

###AbstractSourceCodeReaderRule
基于源代码的逐行解析，我们可以通过它来处理源代码的文本文件。例如：计算文本的长度，混合空格和制表符等等。
###AST Visitor Rules
现在大多数的规则，都是通过继承AbstractASTVisitorRule来实现的。只需要关注里面感兴趣的节点，就能做到大部分的检查。例如想要查看if语句时

```
bool VisitIfStmt(IfStmt *ifStmt)
{
    // do stuff with this if statement
    return true;
}
```
返回值为true是，会继续遍历，为false时，不会再遍历了。

###AST Matcher Rules
如果可能，我们更愿意使用这个。因为它的可读性高。所有的AST matcher规则都继承于```AbstractASTMatcherRule```。

我们需要把每个匹配都放到```setUpMatcher```方法里。每当节点匹配时，就会把AST节点当成一个参数回调回来。我们就可以从刚刚绑定的方法拿到它。然后把它丢到违反集处理。

##Scaffolding
通过它可以创建自定义规则模板。可以定义类别、规则类型、名字、优先级。

例如：

```
./scaffoldRule AllSwitchStatements -c controversial -t ASTMatcher
```

##编译规则
我们需要打包成动态库来完成接下来的工作。Mac端是dylib、linux是so、windows是dll。

##单元测试

把cpp文件转换成xcode项目
cmake -G Xcode

##oclint脚本分析
clang可以 checkout llvm相关的代码
countly可以checkout countly-cpp
googleTest可以checkout googletest相关的
test可以编译测试相关的代码
make可以发布release命令，打成动态库