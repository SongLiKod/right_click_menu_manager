import 'dart:ffi';
import 'package:ffi/ffi.dart';

// shell32.dll 中的 SHChangeNotify 函数
final _shell32 = DynamicLibrary.open('shell32.dll');

typedef _SHChangeNotifyNative = Void Function(
  Uint32 wEventId,
  Uint32 uFlags,
  Pointer<Utf16> dwItem1,
  Pointer<Utf16> dwItem2,
);
typedef _SHChangeNotifyDart = void Function(
  int wEventId,
  int uFlags,
  Pointer<Utf16> dwItem1,
  Pointer<Utf16> dwItem2,
);

final _shChangeNotify = _shell32.lookupFunction<_SHChangeNotifyNative, _SHChangeNotifyDart>(
  'SHChangeNotify',
);

// user32.dll 中的 SendMessageTimeoutW
final _user32 = DynamicLibrary.open('user32.dll');

typedef _SendMessageTimeoutNative = UintPtr Function(
  IntPtr hWnd,
  Uint32 msg,
  UintPtr wParam,
  Pointer<Utf16> lParam,
  Uint32 fuFlags,
  Uint32 uTimeout,
  Pointer<UintPtr> lpdwResult,
);
typedef _SendMessageTimeoutDart = int Function(
  int hWnd,
  int msg,
  int wParam,
  Pointer<Utf16> lParam,
  int fuFlags,
  int uTimeout,
  Pointer<UintPtr> lpdwResult,
);

final _sendMessageTimeout = _user32.lookupFunction<_SendMessageTimeoutNative, _SendMessageTimeoutDart>(
  'SendMessageTimeoutW',
);

// Win32 常量
const int _shcneAssocChanged = 0x08000000;
const int _shcneUpdateItem = 0x00001000;
const int _shcnfIdlist = 0x0000;
const int _shcnfPathw = 0x0005;

const int _hWndBroadcast = 0xFFFF;
const int _wmSettingChange = 0x001A;
const int _smtoAbortIfHung = 0x0002;

/// 系统通知服务 - 通知 Windows 刷新右键菜单
class ShellNotifyService {
  /// 通知系统文件关联已更改，刷新右键菜单
  void notifyAssociationChanged() {
    _shChangeNotify(_shcneAssocChanged, _shcnfIdlist, nullptr, nullptr);
    _broadcastSettingChange();
  }

  /// 通知系统文件已更改
  void notifyFileChanged(String path) {
    final pPath = path.toNativeUtf16();
    _shChangeNotify(_shcneUpdateItem, _shcnfPathw, pPath, nullptr);
    calloc.free(pPath);
    _broadcastSettingChange();
  }

  /// 广播 WM_SETTINGCHANGE 确保 Explorer 刷新
  void _broadcastSettingChange() {
    final pEnvironment = 'Environment'.toNativeUtf16();
    final result = calloc<UintPtr>();
    _sendMessageTimeout(
      _hWndBroadcast,
      _wmSettingChange,
      0,
      pEnvironment,
      _smtoAbortIfHung,
      5000,
      result,
    );
    calloc.free(result);
    calloc.free(pEnvironment);
  }
}
