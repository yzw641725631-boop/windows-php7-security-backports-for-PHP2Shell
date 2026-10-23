# Security / 安全说明

## 中文

当前仅发布 PHP 7.3.4 Windows x64 NTS VC15 的实验性源码移植候选版。其他 7.x 版本、TS、x86、Linux 和特定 Windows Server / 业务配置不因仓库名称而获得支持声明。

本项目未经过独立安全审计或完整漏洞利用回归认证。普通软 OOM 尽量结束当前请求；达到硬限制时仍会退出工作进程。能否自动补充进程由部署方的进程管理器决定。不要仅凭 HTTP 413、500、进程仍存活或某个 INI 项存在就断言漏洞已修复。

报告兼容性或普通安装问题时，请提供版本、架构、TS/NTS、配置变化和去除敏感信息的日志。请不要公开上传完整生产 `php.ini`、凭据、会话或用户文件。

对尚未公开的安全缺陷，如仓库启用了 GitHub 私密漏洞报告功能，请使用仓库 Security → Report a vulnerability。若该入口不可用，先在普通 Issue 中仅请求私密报告渠道，不附利用载荷或敏感数据。本文件不承诺固定修复时间或长期维护期限。

## English

Only the experimental PHP 7.3.4 Windows x64 NTS VC15 source-port candidate is published. The repository name does not imply support for other 7.x versions, TS, x86, Linux, or every Windows Server/application configuration.

No independent security audit or complete exploit-regression certification has been performed. Soft OOM is intended to terminate the current request; the hard limit can terminate a worker. Worker replacement depends on the deployment's process manager. HTTP 413/500, worker survival, or an INI directive's presence is not proof of complete remediation.

For compatibility and installation issues, include version, architecture, TS/NTS, configuration changes and redacted logs. Do not publish production configuration secrets, session data or user uploads.

For an undisclosed vulnerability, use Security → Report a vulnerability if private reporting is enabled for this repository. If unavailable, open an issue asking for a private contact channel without disclosing exploit details or sensitive data. This document does not promise a fixed response time or long-term maintenance period.
