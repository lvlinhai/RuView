# RuView 隐私占用感知二开方案

## 1. 文档目的

本文档用于指导基于当前 `RuView` 仓库进行二次开发，将现有的 WiFi CSI 感知能力收敛为一个可交付、可部署、可收费的 `隐私占用感知` 产品。

本文档面向以下角色：

- 产品负责人
- 后端工程师
- 前端工程师
- 嵌入式/设备工程师
- 交付与实施工程师

本文档只讨论第一阶段商业化产品，不覆盖整仓库的全部能力。

---

## 2. 产品目标

### 2.1 目标产品

将当前项目收敛为一个房间级占用感知系统，面向：

- 办公室会议室
- 联合办公空间
- 零售门店
- 小型酒店/公寓

### 2.2 第一阶段输出能力

第一阶段只交付以下能力：

- 房间实时状态：空闲 / 占用
- 人员进入 / 离开事件
- 驻留时长统计
- 房间利用率统计
- 设备在线状态
- 房间校准流程
- Webhook / BMS / HVAC 联动

### 2.3 第一阶段明确不做

以下能力不纳入 V1：

- DensePose 姿态重建
- 生命体征商业化输出
- 医疗诊断
- 机器人安全急停闭环
- 灾害搜索与救援
- 通用训练平台产品化
- 面向 C 端的智能家居 App

---

## 3. 产品定义

### 3.1 产品定位

本产品不是“卖 WiFi 感知算法”，而是“卖房间是否有人、用了多久、什么时候该联动空调和灯光”。

### 3.2 核心卖点

- 无摄像头，隐私友好
- 无需佩戴设备
- 复用现有 WiFi 环境和低成本 ESP32-S3 节点
- 支持本地部署
- 支持会议室、房间、区域级利用率分析

### 3.3 最小可售 SKU

建议第一阶段只做一个 SKU：

- `会议室占用感知`

交付内容：

- 实时占用状态
- 会议开始 / 结束判断
- 房间可用状态
- 周报 / 月报
- Webhook 联动

---

## 4. 当前仓库可复用资产

当前仓库并不是从零开始。已有较多可复用能力，重点是“收敛”，不是“重写”。

| 能力 | 当前实现 | 路径 | 二开策略 |
|---|---|---|---|
| ESP32 CSI 接入 | 已实现 | `rust-port/wifi-densepose-rs/crates/wifi-densepose-sensing-server/src/main.rs` | 直接复用 |
| REST API / WebSocket 主干 | 已实现 | `rust-port/wifi-densepose-rs/crates/wifi-densepose-sensing-server/src/main.rs` | 在现有服务上扩展 |
| 占用区域检测 | 已实现 | `rust-port/wifi-densepose-rs/crates/wifi-densepose-wasm-edge/src/occupancy.rs` | 复用并封装为业务事件 |
| HVAC Presence 状态机 | 已实现 | `rust-port/wifi-densepose-rs/crates/wifi-densepose-wasm-edge/src/bld_hvac_presence.rs` | 作为房间占用状态机基础 |
| Meeting Room 生命周期 | 已实现 | `rust-port/wifi-densepose-rs/crates/wifi-densepose-wasm-edge/src/bld_meeting_room.rs` | 作为会议室 SKU 核心模块 |
| Customer Flow | 已实现 | `rust-port/wifi-densepose-rs/crates/wifi-densepose-wasm-edge/src/ret_customer_flow.rs` | 作为零售 SKU 的二阶段模块 |
| 录制能力 | 已实现 | `rust-port/wifi-densepose-rs/crates/wifi-densepose-sensing-server/src/recording.rs` | 用于现场数据采集和校准 |
| 校准入口 | 已实现 | `rust-port/wifi-densepose-rs/crates/wifi-densepose-sensing-server/src/main.rs` | 需要业务化封装 |
| Web UI 骨架 | 已实现 | `ui/` | 保留基础设施，重做业务页面 |
| 数据库层 | 仅 stub | `rust-port/wifi-densepose-rs/crates/wifi-densepose-db/` | 需要补实现 |

### 4.1 结论

推荐做法是：

- 不新建独立后端
- 不重写感知链路
- 不先做模型训练平台
- 直接在 `wifi-densepose-sensing-server` 上增加产品层

---

## 5. 当前缺口分析

虽然底层感知能力已有基础，但“商业产品层”明显不足。

### 5.1 业务模型缺口

当前缺少以下核心实体：

- `site`：站点
- `room`：房间
- `sensor_node`：传感器节点
- `deployment`：部署关系
- `calibration_profile`：校准配置
- `occupancy_snapshot`：房间状态快照
- `occupancy_event`：进入/离开/状态变化事件
- `integration_endpoint`：Webhook / BMS / HVAC 集成目标

### 5.2 持久化缺口

当前 `wifi-densepose-db` 仍处于 stub 状态，尚未提供真正可用的：

- SQLite / PostgreSQL 持久化
- migration
- repository
- 房间维度历史查询
- 事件时间线

### 5.3 产品化缺口

当前缺少：

- 面向实施人员的设备配置页面
- 面向运营人员的房间概览页面
- 面向客户的统计报表
- 面向系统集成的稳定业务 API
- 面向现场的标准校准流程
- 面向交付的 Docker 一键启动方案

### 5.4 风险边界缺口

当前仓库能力很强，但产品边界不收敛。如果直接对外售卖“姿态”“穿墙”“生命体征”，将引入：

- 不必要的交付复杂度
- 不必要的误报风险
- 不必要的法律和责任风险

---

## 6. 推荐实现策略

### 6.1 总体策略

采用以下策略进行二开：

- 保留现有 Rust 感知主链路
- 在 `sensing-server` 上增加业务层
- 第一阶段使用 `SQLite`
- 第二阶段再切换 `PostgreSQL`
- UI 只保留业务控制台，不保留研究演示风格
- 所有输出统一转化为“房间业务事件”

### 6.2 不建议的做法

以下做法不建议在第一阶段采用：

- 新建一个单独的 Python/Node 后端包裹 Rust
- 为了商业化而重写 ESP32 接入链路
- 先做多租户云平台
- 先做通用模型训练系统
- 先做复杂 3D 可视化

---

## 7. 目标架构

```text
ESP32-S3 Nodes
    |
    | UDP / CSI frames
    v
RuView sensing-server
    |
    | signal processing + wasm edge modules
    v
Occupancy Product Layer
    |
    | business event mapping
    +--> SQLite / PostgreSQL
    +--> WebSocket live updates
    +--> Webhook / BMS / HVAC integrations
    v
Occupancy Dashboard UI
```

### 7.1 架构分层

建议分为 5 层：

1. `设备接入层`
2. `感知与事件层`
3. `业务服务层`
4. `持久化层`
5. `控制台与集成层`

### 7.2 分层职责

#### 设备接入层

负责：

- 接收 ESP32 UDP 数据
- 维护节点在线状态
- 处理原始 CSI 帧

复用路径：

- `rust-port/wifi-densepose-rs/crates/wifi-densepose-sensing-server/src/main.rs`

#### 感知与事件层

负责：

- 运行 occupancy / hvac / meeting-room 等模块
- 生成感知事件
- 做基础去抖和状态转换

复用路径：

- `rust-port/wifi-densepose-rs/crates/wifi-densepose-wasm-edge/src/occupancy.rs`
- `rust-port/wifi-densepose-rs/crates/wifi-densepose-wasm-edge/src/bld_hvac_presence.rs`
- `rust-port/wifi-densepose-rs/crates/wifi-densepose-wasm-edge/src/bld_meeting_room.rs`

#### 业务服务层

负责：

- 将底层事件转化为房间业务事件
- 维护房间实时状态
- 计算驻留时长和利用率
- 调用集成接口

建议新增目录：

- `rust-port/wifi-densepose-rs/crates/wifi-densepose-sensing-server/src/product/`

建议模块：

- `models.rs`
- `service.rs`
- `events.rs`
- `calibration.rs`
- `integrations.rs`
- `rooms_api.rs`

#### 持久化层

负责：

- 房间、设备、事件、快照入库
- 查询历史数据
- 报表所需的统计查询

建议优先实现：

- SQLite

第二阶段实现：

- PostgreSQL

#### 控制台与集成层

负责：

- 管理房间和设备
- 展示实时状态
- 展示历史统计
- 设置联动接口

复用目录：

- `ui/`

建议新增业务页面目录：

- `ui/occupancy/`

---

## 8. 数据模型设计

### 8.1 第一阶段核心表

建议实现以下数据表：

#### `sites`

字段建议：

- `id`
- `name`
- `code`
- `timezone`
- `created_at`
- `updated_at`

#### `rooms`

字段建议：

- `id`
- `site_id`
- `name`
- `code`
- `room_type`
- `status`
- `calibration_status`
- `notes`
- `created_at`
- `updated_at`

#### `sensor_nodes`

字段建议：

- `id`
- `site_id`
- `room_id`
- `node_id`
- `serial_number`
- `firmware_version`
- `last_seen_at`
- `ip_address`
- `status`
- `created_at`

#### `calibration_profiles`

字段建议：

- `id`
- `room_id`
- `profile_name`
- `baseline_version`
- `started_at`
- `completed_at`
- `status`
- `metadata_json`

#### `occupancy_snapshots`

字段建议：

- `id`
- `room_id`
- `captured_at`
- `occupied`
- `person_count_estimate`
- `motion_score`
- `confidence`
- `state`
- `source`

#### `occupancy_events`

字段建议：

- `id`
- `room_id`
- `event_type`
- `occurred_at`
- `value`
- `confidence`
- `payload_json`

建议事件类型：

- `room_occupied`
- `room_vacant`
- `entry`
- `exit`
- `meeting_started`
- `meeting_ended`
- `room_available`
- `departure_countdown`
- `device_offline`
- `calibration_started`
- `calibration_completed`

#### `integration_endpoints`

字段建议：

- `id`
- `site_id`
- `room_id`
- `type`
- `target_url`
- `secret`
- `enabled`
- `retry_policy_json`

### 8.2 第一阶段不需要的表

第一阶段可以不实现：

- 用户权限细粒度 RBAC
- 多组织复杂隔离
- 账单系统
- 模型仓库
- 大规模时序归档

---

## 9. 业务事件映射

当前仓库已有底层感知事件，但商业产品需要的是稳定、可解释的业务事件。

### 9.1 底层事件来源

主要来源如下：

- Occupancy zones
- HVAC presence
- Meeting room lifecycle
- Customer flow
- Node online/offline

### 9.2 目标业务事件

建议统一映射为以下业务事件：

| 业务事件 | 说明 | 来源模块 |
|---|---|---|
| `room_occupied` | 房间进入占用状态 | `bld_hvac_presence` |
| `room_vacant` | 房间进入空闲状态 | `bld_hvac_presence` |
| `meeting_started` | 会议开始 | `bld_meeting_room` |
| `meeting_ended` | 会议结束 | `bld_meeting_room` |
| `room_available` | 房间恢复可预订 | `bld_meeting_room` |
| `entry` | 进入事件 | `ret_customer_flow` |
| `exit` | 离开事件 | `ret_customer_flow` |
| `zone_occupied` | 某区域激活 | `occupancy` |
| `device_offline` | 设备离线 | 接入层 |
| `calibration_completed` | 校准完成 | 产品层 |

### 9.3 业务事件输出规范

所有业务事件建议统一包含：

- `event_id`
- `site_id`
- `room_id`
- `event_type`
- `occurred_at`
- `confidence`
- `source_module`
- `payload`

---

## 10. API 设计草案

建议不要再暴露“研究型接口”给商业产品前端。新增一组产品接口即可。

### 10.1 房间接口

- `GET /api/v1/rooms`
- `POST /api/v1/rooms`
- `GET /api/v1/rooms/{id}`
- `PATCH /api/v1/rooms/{id}`
- `DELETE /api/v1/rooms/{id}`

### 10.2 实时状态接口

- `GET /api/v1/rooms/{id}/live`
- `GET /api/v1/rooms/{id}/timeline`
- `GET /api/v1/rooms/{id}/stats`
- `GET /api/v1/rooms/{id}/devices`

### 10.3 校准接口

- `POST /api/v1/rooms/{id}/calibration/start`
- `POST /api/v1/rooms/{id}/calibration/stop`
- `GET /api/v1/rooms/{id}/calibration/status`

### 10.4 联动接口

- `GET /api/v1/integrations`
- `POST /api/v1/integrations`
- `POST /api/v1/integrations/{id}/test`
- `PATCH /api/v1/integrations/{id}`

### 10.5 WebSocket

建议保留一个产品级 WebSocket：

- `GET /ws/occupancy`

消息类型建议：

- `room_status_update`
- `occupancy_event`
- `device_status_update`
- `calibration_update`

---

## 11. 前端控制台设计

当前 UI 偏研究演示风格。商业版应改为业务控制台。

### 11.1 页面范围

第一阶段建议只做以下页面：

- 登录页
- 房间总览页
- 房间详情页
- 设备管理页
- 校准页
- 联动配置页
- 报表页

### 11.2 房间总览页

展示：

- 房间名称
- 当前状态
- 今日占用时长
- 今日进入次数
- 最后事件时间
- 设备在线状态

### 11.3 房间详情页

展示：

- 实时状态卡片
- 占用时间线
- 最近事件列表
- 最近 7 天利用率
- 校准状态

### 11.4 报表页

第一阶段只做：

- 日利用率
- 周利用率
- 高峰时段
- 空置率

### 11.5 UI 风格建议

建议：

- 采用 dashboard 风格
- 弱化 3D 可视化
- 强化状态、统计、告警和配置

---

## 12. 推荐代码组织

### 12.1 后端

建议在 `wifi-densepose-sensing-server` 中新增：

```text
src/product/
  api.rs
  calibration.rs
  events.rs
  integrations.rs
  models.rs
  repository.rs
  service.rs
  stats.rs
```

### 12.2 前端

建议在 `ui/` 中新增：

```text
ui/occupancy/
  pages/
  components/
  services/
  store/
```

### 12.3 配置

建议增加：

- `config/rooms.example.json`
- `config/integrations.example.json`
- `docker/occupancy.compose.yml`

---

## 13. 分阶段开发计划

## Phase 0: 收敛产品边界

目标：

- 明确只做房间占用产品
- 明确不交付姿态、生命体征、救援、机器人

交付物：

- 本文档
- 产品范围清单
- API 草案

---

## Phase 1: 持久化基础设施

目标：

- 补齐 SQLite 存储
- 建立房间、设备、事件基本表

任务：

- 实现 schema 和 migrations
- 增加 repository
- 支持事件入库和查询

验收标准：

- 可创建站点和房间
- 可登记设备
- 可查询房间历史事件

---

## Phase 2: 业务事件层

目标：

- 将底层 WASM 事件映射为产品业务事件

任务：

- 接入 `occupancy`
- 接入 `bld_hvac_presence`
- 接入 `bld_meeting_room`
- 统一输出 `occupancy_event`

验收标准：

- 房间状态可稳定切换
- 进入 / 离开事件可记录
- 会议开始 / 结束事件可记录

---

## Phase 3: 房间 API

目标：

- 提供前端可直接使用的业务 API

任务：

- 房间 CRUD
- 实时状态接口
- 时间线接口
- 统计接口
- 校准接口

验收标准：

- 前端不再依赖研究型接口拼接业务逻辑

---

## Phase 4: 商业控制台 UI

目标：

- 提供面向交付和运营的 dashboard

任务：

- 房间总览页
- 房间详情页
- 设备页
- 校准页
- 联动配置页

验收标准：

- 非研发人员可完成基本查看和配置

---

## Phase 5: 联动与交付

目标：

- 支持客户现场接入 HVAC / BMS / Webhook

任务：

- Webhook 推送
- 失败重试
- 测试回调
- Docker Compose
- 配置样例

验收标准：

- 单站点可以本地部署
- 占用事件可推送到外部系统

---

## Phase 6: 现场试点与校准

目标：

- 支持真实客户现场部署验证

任务：

- 标准安装 SOP
- 房间空场校准流程
- 实地录制与误报分析
- 阈值调整

验收标准：

- 试点场景达到预设准确率和延迟指标

---

## 14. 里程碑建议

建议按 8 周节奏推进：

| 周期 | 目标 |
|---|---|
| 第 1 周 | 完成文档、范围确认、技术设计 |
| 第 2-3 周 | SQLite、房间模型、事件表 |
| 第 4 周 | 业务事件映射完成 |
| 第 5 周 | 房间 API 完成 |
| 第 6 周 | Dashboard 第一版完成 |
| 第 7 周 | Webhook 与 Docker 交付完成 |
| 第 8 周 | 现场试点、调参与验收 |

---

## 15. 验收指标建议

以下指标用于内部试点验收，不应直接作为对外承诺。

- 房间占用识别准确率：`>= 95%`
- 误报退出次数：`<= 1 次 / 8 小时`
- 状态变化延迟：`<= 2 秒`
- 设备离线发现时间：`<= 30 秒`
- 校准时间：`<= 5 分钟`

如果场景是会议室，可以增加：

- 会议开始识别偏差：`<= 2 分钟`
- 会议结束识别偏差：`<= 3 分钟`

---

## 16. 风险与约束

### 16.1 技术风险

- 房间多径环境差异大，阈值不可完全硬编码
- 传感器摆位对效果影响大
- 多节点场景调试成本高于单节点
- UI 与产品层目前需要从零补齐不少代码

### 16.2 数据与许可风险

- 仓库核心代码可商用
- 若商业版本依赖非商用数据集训练得到的权重，则必须重新采集商业可用数据

### 16.3 商业风险

- 如果产品边界不收敛，会导致交付复杂度失控
- 如果过早承诺医疗、安全闭环、穿墙监控，会显著提高责任风险

### 16.4 第一阶段风险边界

建议明确声明：

- 第一阶段仅提供空间占用与联动建议
- 不提供安全级闭环控制
- 不提供医疗诊断结论

---

## 17. 交付清单

第一阶段建议交付以下内容：

- 商业版后端服务
- SQLite 持久化
- 房间管理 API
- 实时占用 WebSocket
- 商业控制台 UI
- 设备配置样例
- Docker Compose 部署文件
- 校准 SOP
- 试点验收报告模板

---

## 18. 建议的实施顺序

最推荐的落地顺序如下：

1. 在现有 `sensing-server` 上补齐 SQLite 和业务模型
2. 把 `bld_hvac_presence` 与 `bld_meeting_room` 封装成稳定业务事件
3. 做房间级 API
4. 重做 UI 为 occupancy dashboard
5. 加 Webhook / HVAC 联动
6. 现场录制数据并做阈值校准

不建议的顺序如下：

1. 先做通用训练平台
2. 先做云平台
3. 先做姿态和生命体征商业包装
4. 先做复杂 3D 可视化

---

## 19. 下一步开发建议

如果按本方案继续推进，推荐的第一批代码改动为：

- 实现 `SQLite schema + migrations`
- 在 `sensing-server` 中新增 `product/` 模块
- 增加 `rooms / events / calibrations / integrations` API
- 新建 `ui/occupancy/` 业务页面

建议从“可部署的会议室占用产品”出发，而不是从“通用感知平台”出发。
