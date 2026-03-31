# OpenViking 检索问题最终诊断

## 核心发现

✅ **嵌入模型质量正常** - 直接测试显示模型能正确识别相关性
✅ **索引流程正常** - 文档都已完成语义处理和嵌入生成
❌ **问题在于检索配置** - 使用了固定阈值 0.1，导致所有结果评分相同

## 关键证据

### 1. 日志显示使用了阈值过滤

```
[HierarchicalRetriever] Rerank not configured, using vector search only with threshold=0.1
```

### 2. 所有搜索结果的 score 都是 0.1

```
activity_yesterday - score: 0.1
activity_lastweek - score: 0.1
activity_today_1 - score: 0.1
```

### 3. 嵌入模型实际相似度差异明显

```
查询: "今天做了什么？当前日期是 2026-03-31"
- 今天文档: 0.0839
- 昨天文档: 0.0530
差异: 58% 提升
```

## 根本原因

**OpenViking 的检索器使用了阈值过滤而非相似度排序**

配置问题：
1. `threshold=0.1` - 只返回相似度 > 0.1 的结果
2. 返回结果的 score 被设置为固定值 0.1
3. 没有启用 rerank（重排序）功能
4. 实际的向量相似度被丢弃，无法用于排序

## 解决方案

### 方案 1: 启用 Rerank（推荐）

在 `~/.openviking/ov.conf` 中配置 rerank：

```json
{
  "rerank": {
    "provider": "openai",
    "api_base": "http://localhost:18000/v1",
    "model": "Qwen/Qwen3-VL-8B-Instruct-FP8"
  }
}
```

### 方案 2: 调整阈值

降低阈值以获取更多候选，或移除阈值使用 top-k：

```json
{
  "retrieval": {
    "threshold": 0.0,
    "use_score": true
  }
}
```

### 方案 3: 修改检索器代码

修改 `hierarchical_retriever.py`，保留原始相似度分数而非固定为阈值。

## 验证计划

1. 配置 rerank 或调整阈值
2. 重启 OpenViking 服务
3. 重新运行相关性测试
4. 验证结果排序是否正确
