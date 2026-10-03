/// 编译时注入的构建配置
/// 通过 --dart-define=IS_ADMIN=true/false 控制
class BuildConfig {
  /// 是否为管理员版
  /// true：含管理后台（长按头像入口）
  /// false：普通用户版，无管理入口
  static const bool isAdmin =
      bool.fromEnvironment('IS_ADMIN', defaultValue: false);

  /// 版本名称（用于关于页显示）
  static const String versionName = isAdmin ? '管理版' : '用户版';
}
