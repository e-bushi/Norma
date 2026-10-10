// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit.NSFont
#elseif os(iOS) || os(tvOS) || os(watchOS)
  import UIKit.UIFont
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "FontConvertible.Font", message: "This typealias will be removed in SwiftGen 7.0")
public typealias Fonts = FontConvertible.Font

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Fonts

// swiftlint:disable identifier_name line_length type_body_length
public enum FontFamily {
  public enum Rubik {
    public static let light = FontConvertible(name: "Rubik-Light", family: "Rubik", path: "Rubik-Variable.ttf")
    public static let black = FontConvertible(name: "Rubik-Light_Black", family: "Rubik", path: "Rubik-Variable.ttf")
    public static let bold = FontConvertible(name: "Rubik-Light_Bold", family: "Rubik", path: "Rubik-Variable.ttf")
    public static let extraBold = FontConvertible(name: "Rubik-Light_ExtraBold", family: "Rubik", path: "Rubik-Variable.ttf")
    public static let medium = FontConvertible(name: "Rubik-Light_Medium", family: "Rubik", path: "Rubik-Variable.ttf")
    public static let regular = FontConvertible(name: "Rubik-Light_Regular", family: "Rubik", path: "Rubik-Variable.ttf")
    public static let semiBold = FontConvertible(name: "Rubik-Light_SemiBold", family: "Rubik", path: "Rubik-Variable.ttf")
    public static let all: [FontConvertible] = [light, black, bold, extraBold, medium, regular, semiBold]
  }
  public static let allCustomFonts: [FontConvertible] = [Rubik.all].flatMap { $0 }
  public static func registerAllCustomFonts() {
    allCustomFonts.forEach { $0.register() }
  }
}
// swiftlint:enable identifier_name line_length type_body_length

// MARK: - Implementation Details

public struct FontConvertible {
  public let name: String
  public let family: String
  public let path: String

  #if os(macOS)
  public typealias Font = NSFont
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Font = UIFont
  #endif

  public func font(size: CGFloat) -> Font {
    guard let font = Font(font: self, size: size) else {
      fatalError("Unable to initialize font '\(VariableFont.postScriptName(for: self))' (\(family)) at wght \(VariableFont.weightAxis(for: self))")
    }
    return font
  }

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public func swiftUIFont(size: CGFloat) -> SwiftUI.Font {
    return SwiftUI.Font.custom(self, size: size)
  }

  @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
  public func swiftUIFont(fixedSize: CGFloat) -> SwiftUI.Font {
    return SwiftUI.Font.custom(self, fixedSize: fixedSize)
  }

  @available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
  public func swiftUIFont(size: CGFloat, relativeTo textStyle: SwiftUI.Font.TextStyle) -> SwiftUI.Font {
    return SwiftUI.Font.custom(self, size: size, relativeTo: textStyle)
  }
  #endif

  public func register() {
    // swiftlint:disable:next conditional_returns_on_newline
    guard let url = url else { return }
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
  }

  fileprivate func registerIfNeeded() {
    #if os(iOS) || os(tvOS) || os(watchOS)
    if !UIFont.fontNames(forFamilyName: family).contains(name) {
      register()
    }
    #elseif os(macOS)
    if let url = url, CTFontManagerGetScopeForURL(url as CFURL) == .none {
      register()
    }
    #endif
  }

  fileprivate var url: URL? {
    // swiftlint:disable:next implicit_return
    return BundleToken.bundle.url(forResource: path, withExtension: nil)
  }
}

public extension FontConvertible.Font {
  convenience init?(font: FontConvertible, size: CGFloat) {
    // Rubik is a variable font. `font.name` for anything but Light
    // (Rubik-Light_SemiBold and the rest) is not a real PostScript name.
    guard let resolved = VariableFont.uiFont(font, size: size) else { return nil }
    self.init(descriptor: resolved.fontDescriptor, size: size)
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension SwiftUI.Font {
  static func custom(_ font: FontConvertible, size: CGFloat) -> SwiftUI.Font {
    return VariableFont.swiftUIFont(font, size: size, relativeTo: nil, dynamicTypeSize: .large)
  }
}

@available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
public extension SwiftUI.Font {
  static func custom(_ font: FontConvertible, fixedSize: CGFloat) -> SwiftUI.Font {
    return VariableFont.swiftUIFont(font, size: fixedSize, relativeTo: nil, dynamicTypeSize: .large)
  }

  static func custom(
    _ font: FontConvertible,
    size: CGFloat,
    relativeTo textStyle: SwiftUI.Font.TextStyle
  ) -> SwiftUI.Font {
    return VariableFont.swiftUIFont(
      font,
      size: size,
      relativeTo: textStyle,
      dynamicTypeSize: .large
    )
  }
}
#endif

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
