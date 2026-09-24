// TelegramCustom 模块统一导出
// 此文件仅用于 Bazel 依赖聚合，实际功能由子模块提供

import Foundation

@_exported import TelegramCustomCore
@_exported import SplashScreen
@_exported import LoginScreen

// ==================== CUSTOM START ====================
// 描述：导出 CustomTabBar 和 DiscoverPlaceholder 模块
// 文件：TelegramCustom.swift
// 日期：2026-09-23
@_exported import CustomTabBar
@_exported import DiscoverPlaceholder
// ==================== CUSTOM END ====================

