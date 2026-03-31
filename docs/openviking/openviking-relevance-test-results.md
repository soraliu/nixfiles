# OpenViking 语义检索相关性测试结果

## 测试执行时间
2026-03-31

## 测试环境
- OpenViking 版本: 0.2.13
- 嵌入模型: alexliap/Qwen3-VL-Embedding-2B-FP8-DYNAMIC (dimension: 2048)
- VLM 模型: Qwen/Qwen3-VL-8B-Instruct-FP8
- 测试用户: acme/test

## 测试数据集

### 时间相关数据
- `activity_today.txt` - 2026-03-31 的活动（OpenViking 部署验证）
- `activity_yesterday.txt` - 2026-03-30 的活动（vLLM 模型配置）
- `activity_lastweek.txt` - 2026-03-24 的活动（OpenViking 架构研究）

### 技术主题数据
- `tech_python.txt` - Python 异步编程笔记
- `tech_golang.txt` - Go 并发模式笔记
- `tech_rust.txt` - Rust 所有权系统笔记

### 项目信息数据
- `project_info.txt` - OpenViking 项目信息

## 测试结果汇总

| 测试场景 | 测试用例 | 结果 | 相关性评分 |
|---------|---------|------|-----------|
| 时间相关性 | 查询今天的活动 | ❌ FAIL | 不相关 |
| 时间相关性 | 查询昨天的活动 | ⚠️ PARTIAL | 弱相关 |
| 主题相关性 | Python 异步编程 | ❌ FAIL | 不相关 |
| 混合查询 | 今天+OpenViking | ❌ FAIL | 不相关 |
| 否定查询 | 排除 Python | ⚠️ PARTIAL | 弱相关 |

**总体通过率: 0/5 (0%)**

---

## 详细测试结果

### 测试 1: 时间相关性 - 今天的活动

**查询**: "今天做了什么？当前日期是 2026-03-31"

**预期结果**: 第一条应该是 `activity_today` (2026-03-31)

**实际结果**:
```json
{
  "resources": [
    {
      "uri": "viking://resources/activities/activity_yesterday/activity_yesterday.md",
      "score": 0.1,
      "abstract": "...March 30, 2026..."
    },
    {
      "uri": "viking://resources/activities/activity_lastweek/activity_lastweek.md",
      "score": 0.1,
      "abstract": "...2026-03-24..."
    }
  ],
  "total": 2
}
```

**分析**:
- ❌ **不相关**: 返回的是昨天（3-30）和上周（3-24）的活动
- ❌ 今天（3-31）的活动完全没有出现在结果中
- ❌ 时间理解能力严重不足

**问题**:
1. 嵌入模型无法理解"今天"这个相对时间概念
2. 即使查询中明确说明"当前日期是 2026-03-31"，仍然无法匹配正确日期

---

### 测试 2: 时间相关性 - 昨天的活动

**查询**: "昨天做了什么？当前日期是 2026-03-31，昨天是 2026-03-30"

**预期结果**: 第一条应该是 `activity_yesterday` (2026-03-30)

**实际结果**:
```json
{
  "resources": [
    {
      "uri": "viking://resources/activities/activity_yesterday/activity_yesterday.md",
      "score": 0.1,
      "abstract": "...March 30, 2026..."
    },
    {
      "uri": "viking://resources/activities/activity_lastweek/activity_lastweek.md",
      "score": 0.1,
      "abstract": "...2026-03-24..."
    }
  ],
  "total": 2
}
```

**分析**:
- ⚠️ **弱相关**: 第一条结果确实是昨天的活动
- ✅ 日期匹配正确（2026-03-30）
- ⚠️ 但所有结果的 score 都是 0.1，说明相关性区分度很低

**问题**:
1. 相关性评分过于平均，无法有效区分相关程度
2. 虽然结果正确，但可能是偶然性而非真正的语义理解

---

### 测试 3: 主题相关性 - Python 异步编程

**查询**: "如何在 Python 中进行异步编程？"

**预期结果**: 第一条应该是 `tech_python` (Python 异步编程)

**实际结果**:
```json
{
  "resources": [
    {
      "uri": "viking://resources/tech/tech_golang/tech_golang.md",
      "score": 0.1,
      "abstract": "...Go using goroutines and channels..."
    },
    {
      "uri": "viking://resources/tech/tech_rust/tech_rust.md",
      "score": 0.1,
      "abstract": "...Rust's ownership system..."
    }
  ],
  "total": 2
}
```

**分析**:
- ❌ **不相关**: 返回的是 Go 和 Rust 文档
- ❌ Python 文档完全没有出现在结果中
- ❌ 主题匹配完全失败

**问题**:
1. 无法识别查询中的核心主题"Python"
2. 返回了完全不相关的编程语言文档
3. 这是最严重的相关性问题

---

### 测试 4: 混合查询 - 时间 + 主题

**查询**: "今天（2026-03-31）做了哪些 OpenViking 相关的工作？"

**预期结果**: 应该返回今天的 OpenViking 部署验证活动

**实际结果**:
```json
{
  "resources": [
    {
      "uri": "viking://resources/tech/tech_rust/tech_rust.md",
      "score": 0.1,
      "abstract": "...Rust's ownership system..."
    }
  ],
  "total": 1
}
```

**分析**:
- ❌ **不相关**: 返回的是 Rust 技术文档
- ❌ 既不匹配时间（今天），也不匹配主题（OpenViking）
- ❌ 混合查询完全失败

**问题**:
1. 无法同时处理时间和主题两个维度
2. 返回结果与查询意图完全无关

---

### 测试 5: 否定查询 - 排除特定内容

**查询**: "编程语言相关的笔记，但不要 Python 的"

**预期结果**: 应该返回 Go 和 Rust 文档，不包含 Python

**实际结果**:
```json
{
  "resources": [
    {
      "uri": "viking://resources/tech/tech_golang/tech_golang.md",
      "score": 0.1,
      "abstract": "...Go using goroutines and channels..."
    },
    {
      "uri": "viking://resources/tech/tech_rust/tech_rust.md",
      "score": 0.1,
      "abstract": "...Rust's ownership system..."
    }
  ],
  "total": 2
}
```

**分析**:
- ⚠️ **弱相关**: 返回了 Go 和 Rust，没有返回 Python
- ✅ 排除逻辑似乎生效
- ⚠️ 但可能是因为 Python 文档本身就没有被索引或检索到

**问题**:
1. 无法确定是真正理解了"不要 Python"，还是 Python 文档本身就有问题
2. 需要更多测试来验证否定查询能力

---

## 核心问题分析

### 1. 时间理解能力严重不足

**现象**:
- 无法理解"今天"、"昨天"等相对时间概念
- 即使在查询中明确提供绝对日期（2026-03-31），仍然无法正确匹配

**可能原因**:
- 嵌入模型（Qwen3-VL-Embedding-2B）可能不擅长时间语义理解
- 文档中的日期格式（2026-03-31）与查询中的表述方式不匹配
- 嵌入向量空间中，时间信息的表示不够明确

**建议**:
1. 在文档中添加更多时间相关的上下文（如"今天是..."、"最近的活动"）
2. 考虑使用专门的时间过滤器，而不是依赖语义检索
3. 测试更强大的嵌入模型

### 2. 主题识别能力不足

**现象**:
- 查询"Python 异步编程"返回 Go 和 Rust 文档
- 无法识别查询中的核心关键词

**可能原因**:
- 嵌入模型的词汇表或训练数据可能不够全面
- 文档内容过于简短，语义信息不足
- 嵌入维度（2048）可能不足以区分细粒度的主题差异

**建议**:
1. 增加文档内容的丰富度，提供更多上下文
2. 在文档中重复关键词（如多次提到"Python"）
3. 考虑使用混合检索（关键词 + 语义）

### 3. 相关性评分区分度低

**现象**:
- 所有结果的 score 都是 0.1
- 无法有效区分高相关和低相关的结果

**可能原因**:
- OpenViking 的评分算法可能过于简化
- 嵌入向量的相似度计算可能存在问题
- 可能使用了固定的阈值或归一化方法

**建议**:
1. 检查 OpenViking 的评分算法配置
2. 调整相似度计算方法（cosine vs dot product）
3. 考虑引入重排序（reranking）机制

### 4. 部分文档未被检索到

**现象**:
- 今天的活动（activity_today）在任何查询中都没有出现
- Python 文档在相关查询中也没有出现

**可能原因**:
- 文档可能还没有被完全索引
- 嵌入生成过程可能失败
- 可能存在权限或路径问题

**建议**:
1. 检查嵌入模型的日志，确认所有文档都已处理
2. 增加索引等待时间（从 30 秒增加到 60 秒或更长）
3. 手动触发重新索引

---

## 对比：基础功能 vs 语义相关性

### 基础功能测试（之前的测试）
- ✅ 文件上传: 100% 成功
- ✅ 目录创建: 100% 成功
- ✅ 文件列表: 100% 成功
- ✅ 语义搜索返回结果: 100% 成功

### 语义相关性测试（本次测试）
- ❌ 时间相关性: 0% 通过
- ❌ 主题相关性: 0% 通过
- ❌ 混合查询: 0% 通过
- ⚠️ 否定查询: 部分通过

**结论**: OpenViking 的基础功能正常，但**语义检索的相关性严重不足**，无法满足实际使用场景的需求。

---

## 根本原因推测

基于测试结果，最可能的根本原因是：

### 1. 嵌入模型能力限制
`alexliap/Qwen3-VL-Embedding-2B-FP8-DYNAMIC` 可能：
- 训练数据不足，无法理解复杂的时间和主题语义
- FP8 量化导致精度损失
- 2B 参数规模相对较小，表达能力有限

### 2. 文档内容过于简短
测试文档都非常简短（3-5 行），可能导致：
- 语义信息不足
- 嵌入向量无法充分表达文档含义
- 缺少足够的上下文来区分不同文档

### 3. 索引或检索配置问题
可能存在：
- 索引延迟或失败
- 检索算法配置不当
- 评分机制过于简化

---

## 改进建议

### 短期改进（配置调整）

1. **增加文档内容丰富度**
   - 在每个文档中添加更多描述性文本
   - 重复关键词以增强语义信号
   - 添加时间相关的上下文描述

2. **调整检索参数**
   - 增加返回结果数量（limit）
   - 调整相似度阈值
   - 尝试不同的评分算法

3. **使用混合检索**
   - 结合关键词匹配和语义检索
   - 对时间相关查询使用时间过滤器
   - 对主题查询使用标签或分类

### 中期改进（模型升级）

1. **更换更强大的嵌入模型**
   - 尝试更大参数量的模型（如 7B 或更大）
   - 使用 FP16 而非 FP8 以提高精度
   - 选择专门针对中文优化的模型

2. **引入重排序机制**
   - 使用更强大的模型对初步检索结果进行重排序
   - 提高最终结果的相关性

3. **优化索引流程**
   - 确保所有文档都被正确索引
   - 添加索引状态监控
   - 实现增量索引更新

### 长期改进（架构优化）

1. **实现多阶段检索**
   - 第一阶段：快速召回（关键词 + 粗粒度语义）
   - 第二阶段：精细排序（深度语义理解）
   - 第三阶段：上下文增强（考虑用户历史和偏好）

2. **引入查询理解模块**
   - 识别查询意图（时间查询、主题查询、混合查询）
   - 提取关键实体（日期、主题、人物）
   - 根据意图选择不同的检索策略

3. **建立评估体系**
   - 定期运行相关性测试
   - 收集用户反馈
   - 持续优化检索质量

---

## 结论

OpenViking 的基础架构和 API 功能正常，但**语义检索的相关性严重不足**，主要表现为：

1. ❌ 无法理解时间相关查询
2. ❌ 无法准确匹配主题
3. ❌ 相关性评分区分度低
4. ❌ 部分文档无法被检索到

**当前状态**: OpenViking 可以作为文件存储和基础检索系统使用，但**不适合作为 AI 代理的上下文数据库**，因为它无法提供准确的语义检索结果。

**建议**: 在将 OpenViking 集成到生产环境之前，必须解决语义相关性问题，否则会严重影响 AI 代理的性能和用户体验。

---

## 附录：完整测试命令

```bash
# 测试 1: 今天的活动
curl -X POST http://10.1.1.3:1933/api/v1/search/find \
  -H "X-API-Key: $OV_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"今天做了什么？当前日期是 2026-03-31","target_uri":"viking://resources/activities","limit":3}'

# 测试 2: 昨天的活动
curl -X POST http://10.1.1.3:1933/api/v1/search/find \
  -H "X-API-Key: $OV_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"昨天做了什么？当前日期是 2026-03-31，昨天是 2026-03-30","target_uri":"viking://resources/activities","limit":3}'

# 测试 3: Python 异步编程
curl -X POST http://10.1.1.3:1933/api/v1/search/find \
  -H "X-API-Key: $OV_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"如何在 Python 中进行异步编程？","target_uri":"viking://resources/tech","limit":3}'

# 测试 4: 混合查询
curl -X POST http://10.1.1.3:1933/api/v1/search/find \
  -H "X-API-Key: $OV_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"今天（2026-03-31）做了哪些 OpenViking 相关的工作？","limit":5}'

# 测试 5: 否定查询
curl -X POST http://10.1.1.3:1933/api/v1/search/find \
  -H "X-API-Key: $OV_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"编程语言相关的笔记，但不要 Python 的","target_uri":"viking://resources/tech","limit":3}'
```
