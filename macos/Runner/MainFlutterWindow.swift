import Cocoa
import FlutterMacOS
import window_manager
import bitsdojo_window_macos

class MainFlutterWindow: BitsdojoWindow {

  override func bitsdojo_window_configure() -> UInt {
    return BDW_HIDE_ON_STARTUP
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    self.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces
      
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
