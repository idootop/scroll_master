import 'package:oktoast/oktoast.dart' as ok;

void showToast() async {
  ok.showToast(
    'onTap',
    duration: Duration(milliseconds: 2000),
    animationDuration: Duration(milliseconds: 200),
    position: ok.ToastPosition.center,
  );
}
