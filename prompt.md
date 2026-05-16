帮我生成一个 模块设计需求 到 RTL代码的智能体框架
包含顶层的控制流程（./claude/CLAUDE.md）和 子agents：
* rtl-generator: 根据spec生成rtl代码 dut.v
* formal-verifier：生成python-level正确的输入输出映射csv文件，即出硬件模块正确的输入输出test-plan，例如对于一个浮点加法模块，列出正确的输入输出映射表，需考虑各种corner case
* rtl-verifier：根据csv文件和rtl代码写 testbench.v, 运行iverilog反馈错误信息

agent之间通过文件沟通协作，例如 dut.v / formal.csv / dut_test.v / error.log 等
更重要的是通过顶层的CLAUDE.md管理整个 生成代码 -- 生成测试 -- 仿真报错 -- 修改代码 的整个循环流程

帮我在这个文件夹下设计整个工作环境，先理清一版工作流程，做好文件目录管理，建议隔开每个子agent的工作目录，然后先试着写出三个子agent的系统提示词（包括正确的脚本调用细节）和CLAUDE.md初版

当前bash环境已经装好iverilog，可以直接脚本调用

---

整个框架已经初步搭好：
* 整个设计--验证的循环流程已经写好在.claude/CLAUDE.md中
* 所有subagent的系统提示词都在.claude/agents/中

先尝试按照CLAUDE.md的流程运行projects/example_fadd下的设计任务，检查流程中不合理的地方，优化上述提示词，优化整个框架；
注意如果这里的运行成功指的并非是成功生成符合spec要求的rtl代码，而是整个框架能够正确平滑地运行起来
have a try！