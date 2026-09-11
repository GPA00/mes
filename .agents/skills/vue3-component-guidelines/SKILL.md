<!-- ---
name: vue3-component-guidelines
description: >-
  提供在此项目中创建新的 Vue 3 组件的标准操作程序和代码风格指南。
  每当用户要求创建新的 Vue 组件或视图时，必须自动使用此技能。
---

# Vue 3 组件开发指南

当在此项目中创建或修改 Vue 组件时，请严格遵守以下规则：

## 1. 文件结构
- 使用带有 `.vue` 扩展名的单文件组件 (SFC)。
- 保持标签顺序：`<template>` 在最上，接着是 `<script setup>`，最后是 `<style>`。

## 2. 脚本规范 (Script)
- 必须使用 `<script setup lang="ts">`。
- 必须使用 TypeScript 定义所有变量类型和 Props。
- 尽量避免引入未使用的模块。

## 3. 命名约定
- **组件文件**: 使用 PascalCase (大驼峰)，例如：`UserProfile.vue`。
- **变量与函数**: 使用 camelCase (小驼峰)，例如：`fetchUserData`。
- **CSS 类名**: 使用 kebab-case (短横线)，例如：`.user-profile-container`。

## 4. 样式规范 (Style)
- 必须为样式标签添加 `scoped` 属性，以避免样式污染：`<style scoped lang="scss">`。
- 优先使用现有的 UI 框架组件（如 Element Plus），只有在必要时才手写 CSS。

## 5. 组件标准模板

```vue
<!-- <template>
  <div class="my-component-container">
    <!-- 此处编写 HTML 结构 -->
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

// 1. Props & Emits 定义
const props = defineProps<{
  id: number
  title?: string
}>()

const emit = defineEmits(['update', 'close'])

// 2. 响应式状态
const isLoading = ref(false)

// 3. 内部方法
const initData = async () => {
  isLoading.value = true
  // TODO: 请求逻辑
  isLoading.value = false
}

// 4. 生命周期钩子
onMounted(() => {
  initData()
})
</script>

<style scoped lang="scss">
.my-component-container {
  /* 仅作用于当前组件的样式 */
}
</style> -->
``` -->
