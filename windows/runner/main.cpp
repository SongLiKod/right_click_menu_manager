#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <memory>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present
  HWND console = GetConsoleWindow();
  if (console != nullptr) {
    AttachConsole(ATTACH_PARENT_PROCESS);
  }

  // Initialize COM
  HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  if (FAILED(hr)) {
    return EXIT_FAILURE;
  }

  // Request admin privileges for registry access
  // The app manifest will handle UAC elevation

  flutter::DartProject project(L"data");
  std::vector<std::string> command_line_arguments =
      project.dart_entrypoint_arguments();

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1100, 700);
  if (!window.Create(L"右键菜单管理器", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  CoUninitialize();
  return EXIT_SUCCESS;
}
