# OpenViking Abstract 生成问题根因分析

## 问题现象

1. `activity_today` 文档的 abstract 为空
2. 搜索时 `activity_today` 不出现在结果中
3. 即使文档已完成语义处理，仍然无法被检索

## 日志分析

### 索引处理正常

```
17:25:00 - Processing semantic generation for: activity_today
17:25:19 - Completed semantic generation for: activity_today
17:25:19 - All embedding tasks(3) completed
```

✅ activity_today 的语义处理已完成，耗时 19 秒

### 搜索时被跳过

```
17:32:23 - [RecursiveSearch] Entering URI: viking://resources/activities
17:32:23 - [RecursiveSearch] Entering URI: activity_lastweek
17:32:23 - [RecursiveSearch] Entering URI: activity_yesterday
```

❌ **activity_today 没有被遍历！**

## 根本原因

**检索器的递归搜索逻辑存在问题，导致某些已索引的文档被跳过。**

可能的原因：
1. 目录遍历时的排序或过滤逻辑有 bug
2. abstract 虽然生成了但没有正确写入元数据
3. 检索器使用了某种缓存，导致新文档不可见

## 验证

让我检查 activity_today 的实际元数据状态。
