# 现场照片报告

把散乱的现场照片整理成有编号、可定位、可整改、可再次交付的正式问题清单。

## 当前能力

- 项目级归档：名称、地址、日期、企业、检查人、客户与补充说明。
- 结构化问题：区域、具体位置、类型、严重程度、负责人、期限和整改状态。
- 稳定自动编号：项目内按 `A-001` 递增，已分配编号不会因删除记录而复用。
- 现场照片：相机拍摄或相册导入，支持多张整改前、整改后照片。
- 照片标注：矩形、箭头、文字；标注坐标随问题记录持久化。
- 闭环追踪：待整改、处理中、已完成，可按状态、房间和关键词筛选。
- 正式 PDF：封面汇总、逐项问题、标注照片、前后对比、补充说明和签名页。
- 本地离线：SQLite 保存结构化记录，照片存放在 App Documents，PDF 在 iPhone 本机生成。

## 技术结构

- Flutter 负责数据录入、问题清单、标注编辑和项目管理。
- SQLite (`sqflite`) 保存项目、问题、照片索引与标注 JSON。
- iOS `UIGraphicsPDFRenderer` 负责中文 A4 报告，`QuickLook` 预览，系统分享面板交付。
- 首版仅生成 iOS 工程，最低部署版本由 Flutter 插件约束为 iOS 13。

## 本地运行

```bash
flutter pub get
flutter run -d <iOS Simulator 或设备 ID>
```

静态检查与模型测试：

```bash
flutter analyze
flutter test
```

## 数据与权限边界

照片、项目记录和 PDF 默认不上传网络。App 仅在用户主动拍照或选择照片时请求相机、相册权限；分享报告时由用户在 iOS 系统面板中选择接收方。

## Release 打包边界

- `artifacts/` 只存放本地验证截图并由 Git 忽略，禁止加入 `pubspec.yaml` assets。
- Flutter 测试只放在 `test/`，原生测试只属于 `RunnerTests` Target；两者都不属于 Runner 的生产资源。
- Release 构建会执行 `ios/scripts/release_input_guard.sh`，发现测试文件、验证截图或 Flutter 默认占位图标会直接失败。
- 当前 AppIcon 仍是 Flutter 默认占位图标，因此正式 Archive 默认被阻止；收到确认后的品牌图标并替换全套尺寸后才可发布。
- 旧的透明 `LaunchImage` 已从 LaunchScreen 和 Assets 中移除，启动页只使用正式的纯色系统背景。

## 尚未覆盖

- Android 报告生成与分享。
- 企业 Logo、可配置 PDF 版式和手写签名画布。
- 云同步、多人协作、账号权限与 AI 图片识别。
- 真机相机、系统相册及大批量项目的性能验证。
