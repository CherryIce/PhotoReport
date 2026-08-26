import Flutter
import QuickLook
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, QLPreviewControllerDataSource {
  private var previewURL: URL?
  private let pdfInk = UIColor(red: 0.09, green: 0.19, blue: 0.18, alpha: 1)
  private let pdfMuted = UIColor(red: 0.38, green: 0.45, blue: 0.44, alpha: 1)

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerPhotoReportPlugin(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerPhotoReportPlugin(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "PhotoReportPDF") else { return }
    let channel = FlutterMethodChannel(
      name: "com.starburst.photo_report/report",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleReportCall(call, result: result)
    }
  }

  private func handleReportCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "invalid_arguments", message: "缺少报告参数", details: nil))
      return
    }
    switch call.method {
    case "generateReport":
      guard
        let project = arguments["project"] as? [String: Any],
        let issues = arguments["issues"] as? [[String: Any]]
      else {
        result(FlutterError(code: "invalid_payload", message: "报告数据格式错误", details: nil))
        return
      }
      do {
        let url = try generateReport(project: project, issues: issues)
        result(url.path)
      } catch {
        result(FlutterError(code: "pdf_generation_failed", message: error.localizedDescription, details: nil))
      }
    case "previewReport":
      guard let path = arguments["path"] as? String, FileManager.default.fileExists(atPath: path) else {
        result(FlutterError(code: "missing_file", message: "找不到报告文件", details: nil))
        return
      }
      previewURL = URL(fileURLWithPath: path)
      let preview = QLPreviewController()
      preview.dataSource = self
      currentViewController()?.present(preview, animated: true)
      result(nil)
    case "shareReport":
      guard let path = arguments["path"] as? String, FileManager.default.fileExists(atPath: path) else {
        result(FlutterError(code: "missing_file", message: "找不到报告文件", details: nil))
        return
      }
      let activity = UIActivityViewController(
        activityItems: [URL(fileURLWithPath: path)],
        applicationActivities: nil
      )
      if let popover = activity.popoverPresentationController,
         let view = currentViewController()?.view {
        popover.sourceView = view
        popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 60, width: 1, height: 1)
      }
      currentViewController()?.present(activity, animated: true)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    previewURL == nil ? 0 : 1
  }

  func previewController(
    _ controller: QLPreviewController,
    previewItemAt index: Int
  ) -> QLPreviewItem {
    previewURL! as NSURL
  }

  private func currentViewController() -> UIViewController? {
    var current = window?.rootViewController
    while true {
      if let presented = current?.presentedViewController {
        current = presented
      } else if let navigation = current as? UINavigationController {
        current = navigation.visibleViewController
      } else if let tabs = current as? UITabBarController {
        current = tabs.selectedViewController
      } else {
        return current
      }
    }
  }

  func generateReport(
    project: [String: Any],
    issues: [[String: Any]]
  ) throws -> URL {
    let fileManager = FileManager.default
    let documents = try fileManager.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let reports = documents.appendingPathComponent("PhotoReport/Reports", isDirectory: true)
    try fileManager.createDirectory(at: reports, withIntermediateDirectories: true)
    let rawName = project.string("name", fallback: "现场报告")
    let safeName = rawName
      .replacingOccurrences(of: "/", with: "-")
      .replacingOccurrences(of: ":", with: "-")
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    let url = reports.appendingPathComponent("\(safeName)-\(formatter.string(from: Date())).pdf")

    let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)
    let format = UIGraphicsPDFRendererFormat()
    format.documentInfo = [
      kCGPDFContextTitle as String: "\(rawName) 现场问题报告",
      kCGPDFContextCreator as String: "现场照片报告",
    ]
    let renderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)
    var pageNumber = 0
    try renderer.writePDF(to: url) { context in
      func beginPage() {
        context.beginPage()
        pageNumber += 1
        UIColor.white.setFill()
        context.cgContext.fill(pageBounds)
      }

      func footer() {
        let text = "现场照片报告  ·  第 \(pageNumber) 页"
        drawText(
          text,
          in: CGRect(x: 42, y: 814, width: 511, height: 14),
          font: .systemFont(ofSize: 8),
          color: UIColor(red: 0.43, green: 0.50, blue: 0.49, alpha: 1),
          alignment: .center
        )
      }

      beginPage()
      drawCover(project: project, issues: issues, pageBounds: pageBounds)
      footer()

      for issue in issues {
        let photos = issue["photos"] as? [[String: Any]] ?? []
        let chunks: [[[String: Any]]]
        if photos.isEmpty {
          chunks = [[]]
        } else {
          chunks = stride(from: 0, to: photos.count, by: 4).map {
            Array(photos[$0..<min($0 + 4, photos.count)])
          }
        }
        for (chunkIndex, chunk) in chunks.enumerated() {
          beginPage()
          drawIssuePage(
            issue: issue,
            photos: chunk,
            continuation: chunkIndex > 0,
            pageBounds: pageBounds
          )
          footer()
        }
      }

      beginPage()
      drawSignoff(project: project, issues: issues, pageBounds: pageBounds)
      footer()
    }
    return url
  }

  private func drawCover(
    project: [String: Any],
    issues: [[String: Any]],
    pageBounds: CGRect
  ) {
    let teal = UIColor(red: 0.043, green: 0.459, blue: 0.420, alpha: 1)
    teal.setFill()
    UIRectFill(CGRect(x: 0, y: 0, width: pageBounds.width, height: 17))

    let company = project.string("companyName", fallback: "现场质量检查")
    drawText(company, in: CGRect(x: 42, y: 48, width: 511, height: 24), font: .boldSystemFont(ofSize: 13), color: teal)
    drawText(
      "现场问题检查报告",
      in: CGRect(x: 42, y: 132, width: 511, height: 54),
      font: .boldSystemFont(ofSize: 34),
      color: UIColor(red: 0.09, green: 0.19, blue: 0.18, alpha: 1)
    )
    drawText(
      "FIELD ISSUE REPORT",
      in: CGRect(x: 44, y: 190, width: 511, height: 22),
      font: .systemFont(ofSize: 11, weight: .semibold),
      color: UIColor(red: 0.41, green: 0.49, blue: 0.47, alpha: 1)
    )

    let infoRect = CGRect(x: 42, y: 254, width: 511, height: 190)
    UIColor(red: 0.95, green: 0.97, blue: 0.965, alpha: 1).setFill()
    UIBezierPath(roundedRect: infoRect, cornerRadius: 14).fill()
    drawText(project.string("name"), in: CGRect(x: 64, y: 278, width: 467, height: 30), font: .boldSystemFont(ofSize: 20), color: pdfInk)
    drawInfoRow("项目地址", value: project.string("address"), y: 324)
    drawInfoRow("检查日期", value: project.string("inspectionDate"), y: 356)
    drawInfoRow("检查人员", value: project.string("inspectorName", fallback: "未填写"), y: 388)

    let pending = issues.filter { $0.string("status") == "待整改" }.count
    let progress = issues.filter { $0.string("status") == "处理中" }.count
    let completed = issues.filter { $0.string("status") == "已完成" }.count
    let high = issues.filter { $0.string("severity") == "高" }.count
    let metrics = [
      ("问题总数", issues.count, UIColor(red: 0.09, green: 0.19, blue: 0.18, alpha: 1)),
      ("待整改", pending, UIColor(red: 0.80, green: 0.42, blue: 0.13, alpha: 1)),
      ("处理中", progress, UIColor(red: 0.17, green: 0.41, blue: 0.72, alpha: 1)),
      ("已完成", completed, UIColor(red: 0.14, green: 0.52, blue: 0.36, alpha: 1)),
      ("高风险", high, UIColor(red: 0.78, green: 0.23, blue: 0.23, alpha: 1)),
    ]
    let metricWidth: CGFloat = 94
    for (index, metric) in metrics.enumerated() {
      let x = 42 + CGFloat(index) * (metricWidth + 10)
      drawMetric(label: metric.0, value: metric.1, color: metric.2, rect: CGRect(x: x, y: 482, width: metricWidth, height: 88))
    }

    let rooms = Array(Set(issues.map { $0.string("room") })).filter { !$0.isEmpty }.sorted()
    drawText("检查范围", in: CGRect(x: 42, y: 618, width: 511, height: 24), font: .boldSystemFont(ofSize: 15), color: pdfInk)
    drawText(
      rooms.isEmpty ? "尚未记录检查区域" : rooms.joined(separator: "  ·  "),
      in: CGRect(x: 42, y: 650, width: 511, height: 64),
      font: .systemFont(ofSize: 12),
      color: UIColor(red: 0.35, green: 0.43, blue: 0.42, alpha: 1)
    )
    drawText(
      "本报告中的问题编号、位置、状态和现场照片共同构成交接与整改依据。",
      in: CGRect(x: 42, y: 756, width: 511, height: 28),
      font: .systemFont(ofSize: 9),
      color: UIColor(red: 0.43, green: 0.50, blue: 0.49, alpha: 1)
    )
  }

  private func drawInfoRow(_ label: String, value: String, y: CGFloat) {
    drawText(label, in: CGRect(x: 64, y: y, width: 74, height: 22), font: .systemFont(ofSize: 10), color: pdfMuted)
    drawText(value, in: CGRect(x: 145, y: y, width: 386, height: 22), font: .systemFont(ofSize: 11, weight: .medium), color: pdfInk)
  }

  private func drawMetric(label: String, value: Int, color: UIColor, rect: CGRect) {
    color.withAlphaComponent(0.09).setFill()
    UIBezierPath(roundedRect: rect, cornerRadius: 12).fill()
    drawText("\(value)", in: CGRect(x: rect.minX + 13, y: rect.minY + 15, width: rect.width - 26, height: 30), font: .boldSystemFont(ofSize: 23), color: color)
    drawText(label, in: CGRect(x: rect.minX + 13, y: rect.minY + 53, width: rect.width - 26, height: 18), font: .systemFont(ofSize: 9), color: pdfMuted)
  }

  private func drawIssuePage(
    issue: [String: Any],
    photos: [[String: Any]],
    continuation: Bool,
    pageBounds: CGRect
  ) {
    let teal = UIColor(red: 0.043, green: 0.459, blue: 0.420, alpha: 1)
    let code = issue.string("code")
    teal.setFill()
    UIBezierPath(roundedRect: CGRect(x: 42, y: 38, width: 76, height: 29), cornerRadius: 7).fill()
    drawText(code, in: CGRect(x: 42, y: 45, width: 76, height: 16), font: .boldSystemFont(ofSize: 11), color: .white, alignment: .center)
    drawText(
      continuation ? "补充照片" : issue.string("category"),
      in: CGRect(x: 130, y: 40, width: 315, height: 26),
      font: .boldSystemFont(ofSize: 19),
      color: pdfInk
    )
    drawPill(issue.string("severity") + "风险", x: 455, y: 40, color: severityColor(issue.string("severity")))
    drawPill(issue.string("status"), x: 455, y: 72, color: statusColor(issue.string("status")))

    var photosY: CGFloat = 104
    if !continuation {
      let detailRect = CGRect(x: 42, y: 92, width: 511, height: 151)
      UIColor(red: 0.955, green: 0.97, blue: 0.966, alpha: 1).setFill()
      UIBezierPath(roundedRect: detailRect, cornerRadius: 12).fill()
      drawDetailPair(label: "位置", value: "\(issue.string("room")) / \(issue.string("location"))", x: 58, y: 111, width: 300)
      drawDetailPair(label: "负责人", value: issue.string("assignee", fallback: "未填写"), x: 365, y: 111, width: 168)
      drawDetailPair(label: "整改期限", value: issue.string("dueDate", fallback: "未设置"), x: 365, y: 154, width: 168)
      drawText("问题描述", in: CGRect(x: 58, y: 157, width: 72, height: 17), font: .systemFont(ofSize: 9), color: pdfMuted)
      drawText(issue.string("description"), in: CGRect(x: 58, y: 177, width: 292, height: 50), font: .systemFont(ofSize: 10.5), color: pdfInk)
      photosY = 265
    }

    if photos.isEmpty {
      UIColor(red: 0.95, green: 0.96, blue: 0.96, alpha: 1).setFill()
      UIBezierPath(roundedRect: CGRect(x: 42, y: photosY, width: 511, height: 250), cornerRadius: 12).fill()
      drawText("此问题未附现场照片", in: CGRect(x: 42, y: photosY + 112, width: 511, height: 24), font: .systemFont(ofSize: 12), color: pdfMuted, alignment: .center)
      return
    }

    let cellWidth: CGFloat = 248
    let cellHeight: CGFloat = 238
    for (index, photo) in photos.enumerated() {
      let column = index % 2
      let row = index / 2
      let cell = CGRect(
        x: 42 + CGFloat(column) * 263,
        y: photosY + CGFloat(row) * 252,
        width: cellWidth,
        height: cellHeight
      )
      drawPhoto(photo, in: cell)
    }
  }

  private func drawDetailPair(label: String, value: String, x: CGFloat, y: CGFloat, width: CGFloat) {
    drawText(label, in: CGRect(x: x, y: y, width: width, height: 16), font: .systemFont(ofSize: 9), color: pdfMuted)
    drawText(value, in: CGRect(x: x, y: y + 18, width: width, height: 20), font: .systemFont(ofSize: 10.5, weight: .semibold), color: pdfInk)
  }

  private func drawPill(_ text: String, x: CGFloat, y: CGFloat, color: UIColor) {
    let rect = CGRect(x: x, y: y, width: 98, height: 24)
    color.withAlphaComponent(0.1).setFill()
    UIBezierPath(roundedRect: rect, cornerRadius: 12).fill()
    drawText(text, in: CGRect(x: x, y: y + 6, width: 98, height: 13), font: .boldSystemFont(ofSize: 8.5), color: color, alignment: .center)
  }

  private func drawPhoto(_ photo: [String: Any], in rect: CGRect) {
    UIColor(red: 0.94, green: 0.96, blue: 0.955, alpha: 1).setFill()
    UIBezierPath(roundedRect: rect, cornerRadius: 10).fill()
    drawText(photo.string("phase"), in: CGRect(x: rect.minX + 9, y: rect.minY + 7, width: rect.width - 18, height: 16), font: .boldSystemFont(ofSize: 9), color: pdfMuted)
    let frame = CGRect(x: rect.minX + 7, y: rect.minY + 28, width: rect.width - 14, height: rect.height - 35)
    guard let image = UIImage(contentsOfFile: photo.string("path")) else {
      drawText("照片文件不可用", in: frame, font: .systemFont(ofSize: 10), color: pdfMuted, alignment: .center)
      return
    }
    let imageRect = aspectFit(image.size, inside: frame)
    UIColor(red: 0.09, green: 0.12, blue: 0.12, alpha: 1).setFill()
    UIRectFill(frame)
    image.draw(in: imageRect)
    let annotations = photo["annotations"] as? [[String: Any]] ?? []
    for annotation in annotations {
      drawAnnotation(annotation, in: imageRect)
    }
  }

  private func drawAnnotation(_ annotation: [String: Any], in rect: CGRect) {
    func number(_ key: String) -> CGFloat {
      CGFloat((annotation[key] as? NSNumber)?.doubleValue ?? 0)
    }
    let start = CGPoint(x: rect.minX + number("x1") * rect.width, y: rect.minY + number("y1") * rect.height)
    let end = CGPoint(x: rect.minX + number("x2") * rect.width, y: rect.minY + number("y2") * rect.height)
    let red = UIColor(red: 0.93, green: 0.08, blue: 0.08, alpha: 1)
    let path = UIBezierPath()
    path.lineWidth = 2.4
    red.setStroke()
    switch annotation.string("kind") {
    case "rectangle":
      path.append(UIBezierPath(rect: CGRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))))
      path.stroke()
    case "arrow":
      path.move(to: start)
      path.addLine(to: end)
      let angle = atan2(end.y - start.y, end.x - start.x)
      let length: CGFloat = 12
      path.move(to: end)
      path.addLine(to: CGPoint(x: end.x - cos(angle - 0.58) * length, y: end.y - sin(angle - 0.58) * length))
      path.move(to: end)
      path.addLine(to: CGPoint(x: end.x - cos(angle + 0.58) * length, y: end.y - sin(angle + 0.58) * length))
      path.stroke()
    case "text":
      let text = annotation.string("text")
      let textRect = CGRect(x: start.x, y: start.y, width: min(130, rect.maxX - start.x), height: 32)
      red.withAlphaComponent(0.88).setFill()
      UIBezierPath(roundedRect: textRect, cornerRadius: 4).fill()
      drawText(text, in: textRect.insetBy(dx: 5, dy: 6), font: .boldSystemFont(ofSize: 8), color: .white)
    default:
      break
    }
  }

  private func drawSignoff(
    project: [String: Any],
    issues: [[String: Any]],
    pageBounds: CGRect
  ) {
    let teal = UIColor(red: 0.043, green: 0.459, blue: 0.420, alpha: 1)
    teal.setFill()
    UIRectFill(CGRect(x: 0, y: 0, width: pageBounds.width, height: 17))
    drawText("补充说明与确认", in: CGRect(x: 42, y: 58, width: 511, height: 38), font: .boldSystemFont(ofSize: 26), color: pdfInk)
    drawText("项目：\(project.string("name"))", in: CGRect(x: 42, y: 108, width: 511, height: 22), font: .systemFont(ofSize: 11, weight: .semibold), color: pdfMuted)

    let notesRect = CGRect(x: 42, y: 164, width: 511, height: 210)
    UIColor(red: 0.955, green: 0.97, blue: 0.966, alpha: 1).setFill()
    UIBezierPath(roundedRect: notesRect, cornerRadius: 12).fill()
    drawText("补充说明", in: CGRect(x: 60, y: 184, width: 120, height: 22), font: .boldSystemFont(ofSize: 13), color: teal)
    drawText(project.string("notes", fallback: "无"), in: CGRect(x: 60, y: 219, width: 475, height: 132), font: .systemFont(ofSize: 11), color: pdfInk)

    let unfinished = issues.filter { $0.string("status") != "已完成" }.count
    drawText(
      "截至报告生成时，共记录 \(issues.count) 项问题，其中 \(unfinished) 项尚未完成整改。报告再次导出时会反映最新状态。",
      in: CGRect(x: 42, y: 411, width: 511, height: 52),
      font: .systemFont(ofSize: 10),
      color: pdfMuted
    )

    drawSignature(title: "检查方签名", name: project.string("inspectorName"), rect: CGRect(x: 42, y: 520, width: 240, height: 150))
    drawSignature(title: "业主/客户签名", name: project.string("clientName"), rect: CGRect(x: 313, y: 520, width: 240, height: 150))
    drawText("确认日期：________年____月____日", in: CGRect(x: 42, y: 718, width: 511, height: 26), font: .systemFont(ofSize: 11), color: pdfMuted, alignment: .center)
  }

  private func drawSignature(title: String, name: String, rect: CGRect) {
    UIColor(red: 0.97, green: 0.98, blue: 0.98, alpha: 1).setFill()
    UIBezierPath(roundedRect: rect, cornerRadius: 12).fill()
    drawText(title, in: CGRect(x: rect.minX + 16, y: rect.minY + 15, width: rect.width - 32, height: 20), font: .boldSystemFont(ofSize: 12), color: pdfInk)
    drawText(name.isEmpty ? "" : "姓名：\(name)", in: CGRect(x: rect.minX + 16, y: rect.maxY - 39, width: rect.width - 32, height: 20), font: .systemFont(ofSize: 10), color: pdfMuted)
    UIColor(red: 0.78, green: 0.82, blue: 0.81, alpha: 1).setStroke()
    let line = UIBezierPath()
    line.move(to: CGPoint(x: rect.minX + 16, y: rect.maxY - 48))
    line.addLine(to: CGPoint(x: rect.maxX - 16, y: rect.maxY - 48))
    line.lineWidth = 0.7
    line.stroke()
  }

  private func aspectFit(_ imageSize: CGSize, inside rect: CGRect) -> CGRect {
    guard imageSize.width > 0, imageSize.height > 0 else { return rect }
    let scale = min(rect.width / imageSize.width, rect.height / imageSize.height)
    let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    return CGRect(
      x: rect.midX - size.width / 2,
      y: rect.midY - size.height / 2,
      width: size.width,
      height: size.height
    )
  }

  private func severityColor(_ value: String) -> UIColor {
    switch value {
    case "高": return UIColor(red: 0.78, green: 0.23, blue: 0.23, alpha: 1)
    case "中": return UIColor(red: 0.80, green: 0.42, blue: 0.13, alpha: 1)
    default: return UIColor(red: 0.35, green: 0.46, blue: 0.44, alpha: 1)
    }
  }

  private func statusColor(_ value: String) -> UIColor {
    switch value {
    case "已完成": return UIColor(red: 0.14, green: 0.52, blue: 0.36, alpha: 1)
    case "处理中": return UIColor(red: 0.17, green: 0.41, blue: 0.72, alpha: 1)
    default: return UIColor(red: 0.80, green: 0.42, blue: 0.13, alpha: 1)
    }
  }

  private func drawText(
    _ text: String,
    in rect: CGRect,
    font: UIFont,
    color: UIColor,
    alignment: NSTextAlignment = .left
  ) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineSpacing = 2
    (text as NSString).draw(
      in: rect,
      withAttributes: [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph,
      ]
    )
  }
}

private extension Dictionary where Key == String, Value == Any {
  func string(_ key: String, fallback: String = "") -> String {
    let value = self[key] as? String ?? ""
    return value.isEmpty ? fallback : value
  }
}
