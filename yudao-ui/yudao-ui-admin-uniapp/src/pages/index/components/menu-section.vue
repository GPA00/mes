<template>
  <!-- 根据布局开关渲染对应外壳，四种布局共用同一份菜单数据 -->
  <MenuLayoutSection
    v-if="currentLayout === 'section'"
    :groups="menuGroups"
    :favorites="favoriteMenuItems"
    :recents="recentMenuItems"
  />
  <MenuLayoutAccordion
    v-else-if="currentLayout === 'accordion'"
    :groups="menuGroups"
    :favorites="favoriteMenuItems"
    :recents="recentMenuItems"
  />
  <MenuLayoutTabs
    v-else-if="currentLayout === 'tabs'"
    :groups="menuGroups"
    :favorites="favoriteMenuItems"
    :recents="recentMenuItems"
  />
  <MenuLayoutSidebar
    v-else
    :groups="menuGroups"
    :favorites="favoriteMenuItems"
    :recents="recentMenuItems"
  />
</template>

<script lang="ts" setup>
import type { MenuGroup, MenuItem, MenuLayout } from '../index'
import { useUserStore } from '@/store/user'
import { getMenuGroups, getMenuItemByKey, menuLayout } from '../index'
import MenuLayoutAccordion from './menu-layout-accordion.vue'
import MenuLayoutSection from './menu-layout-section.vue'
import MenuLayoutSidebar from './menu-layout-sidebar.vue'
import MenuLayoutTabs from './menu-layout-tabs.vue'

defineOptions({
  name: 'MenuSection',
})

const userStore = useUserStore()

/** 菜单分组列表 */
const menuGroups = ref<MenuGroup[]>([])

/** 当前布局（onShow 时与全局开关同步，保证从设置页返回即时生效） */
const currentLayout = ref<MenuLayout>(menuLayout.value)

/** 常用服务菜单（从 store 中计算得出） */
const favoriteMenuItems = computed<MenuItem[]>(() => {
  const keys = userStore.favoriteMenus
  if (!keys || keys.length === 0) {
    return []
  }
  return keys.map(key => getMenuItemByKey(key)).filter(Boolean) as MenuItem[]
})

/** 最近使用菜单（从 store 中计算得出，按点击时间倒序） */
const recentMenuItems = computed<MenuItem[]>(() => {
  const keys = userStore.recentMenus
  if (!keys || keys.length === 0) {
    return []
  }
  return keys.map(key => getMenuItemByKey(key)).filter(Boolean) as MenuItem[]
})

/** 初始化 */
function initData() {
  menuGroups.value = getMenuGroups()
  currentLayout.value = menuLayout.value
}

/**
 * 初始化
 *
 * 不使用 onMounted 的原因是：登录后，页面可能已经挂载，但数据需要重新初始化；
 * 同时从「编辑工作台」返回时也会触发，用于同步最新布局。
 */
onShow(() => {
  initData()
})
</script>
