# Changelog (Personal Fork)

> This is a **personal modified fork**.
> Changes are tailored for local usage and experimentation and may diverge from upstream behavior.

> 本项目为 **个人魔改版本**，包含针对本地使用与实验性的改动，可能与原仓库存在较大差异。

---

## [2.0.1-canguroMIO] - 2026-01-01

### ✨ Added | 新增

* **Hybrid Map Mode（混合地图模式）**
  Uses **AutoNavi (Amap) Satellite imagery** as the base layer with a transparent **Road Network overlay**, improving readability of newly built areas.
  使用 **高德卫星图** 作为底图，并叠加透明 **道路网图层**，更清晰展示新建区域。

* **GCJ-02 Coordinate Rectification（火星坐标纠偏）**
  Implemented `CoordConv` to automatically convert GPS (WGS-84) coordinates for tracks, markers, and current position, eliminating offsets on Chinese maps.
  引入 `CoordConv` 实现 **GCJ-02 坐标转换**，修复轨迹、标记点与当前位置在国内地图中的偏移问题。

* **Local User Profile Overrides（本地用户信息覆盖）**

  * Local nickname stored on-device, overriding cloud username in UI
    支持本地昵称设置，界面优先显示本地昵称
  * Local avatar selection via camera or photo gallery
    支持通过相机或相册设置本地头像

* **Avatar Image Editing（头像编辑）**
  Integrated `image_cropper` for 1:1 cropping, zooming, and rotation during avatar upload.
  集成 `image_cropper`，支持头像 1:1 裁剪、缩放与旋转。

* **Camera Integration（相机支持）**
  Added direct camera capture for avatar updates.
  新增头像拍照功能。

* **iOS Permissions（iOS 权限补全）**
  Added missing permission descriptions to `Info.plist`:

  * `NSCameraUsageDescription`
  * `NSPhotoLibraryUsageDescription`

* **Localization Keys（本地化文案）**
  Added translation keys for avatar and nickname related actions (e.g. `pick_from_gallery`, `take_photo`, `edit_avatar`, `set_nickname`).

---

### 🔧 Changed | 调整

* **Map Tile Source**
  Switched tile provider to `wprd0{s}.is.autonavi.com` for improved stability and reduced tile blocking.
  地图瓦片源切换至 `wprd0{s}.is.autonavi.com`，提升稳定性并减少瓦片缺失。

* **Map Zoom & Rendering Behavior**

  * Set `maxNativeZoom: 18` and `maxZoom: 22` to prevent white screens at high zoom levels
    通过限制原生缩放级别，避免高倍缩放白屏
  * Disabled `RetinaMode` to avoid invalid tile requests
    关闭 `RetinaMode`，避免无效瓦片请求
  * Increased HTTP concurrency (`maxConnectionsPerHost: 15`) for smoother tile loading
    提升瓦片加载并发性能

* **Anti-Scraping Mitigation**
  Added browser-like `User-Agent` headers to tile requests to reduce server-side blocking.
  为瓦片请求添加浏览器风格 `User-Agent`，降低反爬拦截概率。

* **Profile UI Interaction**
  User profile card now supports tap-to-edit for both avatar and nickname.
  用户资料卡片支持点击头像或昵称直接编辑。

---

### 🐛 Fixed | 修复

* **iOS Build (Apple Silicon)**
  Fixed `ffi` Ruby gem compatibility issues on M1/M2/M3 Macs.
  修复 Apple Silicon 设备上的 `ffi` 兼容性问题。

* **RetinaMode Instantiation Bug**
  Fixed incorrect constant initialization syntax.
  修复 `RetinaMode` 常量初始化错误。

* **iPad Dialog Auto-Dismiss**
  Prevented dialogs from closing unintentionally on iPad by setting `barrierDismissible: false`.
  修复 iPad 上弹窗误触背景自动关闭的问题。

* **Track-to-Map Offset (~500m)**
  Fixed visible offset between recorded tracks and map background.
  修复轨迹与地图背景之间约 500 米的偏移问题。

---
