import SwiftUI

/// Jetons de couleur du design system « Nocturne » (voir DESIGN.md).
/// Valeurs reprises telles quelles de styles.css — ne pas inventer de couleur hors rampe.
enum Nocturne {
    static let fond = Color(hex: 0x161826)
    static let surface = Color(hex: 0x232532)
    static let texte = Color(hex: 0xE9E9ED)
    static let accent = Color(hex: 0x9184D9)

    // Rampe neutre 100–900
    static let neutre100 = Color(hex: 0xF3F5FE)
    static let neutre200 = Color(hex: 0xE4E7F5)
    static let neutre300 = Color(hex: 0xCFD3E5)
    static let neutre400 = Color(hex: 0xB2B6CA)
    static let neutre500 = Color(hex: 0x9397AB)
    static let neutre600 = Color(hex: 0x75798C)
    static let neutre700 = Color(hex: 0x595D6C)
    static let neutre800 = Color(hex: 0x3F424D)
    static let neutre900 = Color(hex: 0x292B31)

    // Rampe accent 100–900
    static let accent100 = Color(hex: 0xF5F4FF)
    static let accent200 = Color(hex: 0xE7E5FE)
    static let accent300 = Color(hex: 0xD2CEFD)
    static let accent400 = Color(hex: 0xB5ABFC)
    static let accent500 = Color(hex: 0x968AE0)
    static let accent600 = Color(hex: 0x796CBF)
    static let accent700 = Color(hex: 0x5D5294)
    static let accent800 = Color(hex: 0x423A6A)
    static let accent900 = Color(hex: 0x2B2741)

    // Fond de section (héros du Parcours) — aplat saturé réservé à cet usage
    static let section = Color(hex: 0x262A60)
    static let sectionLueur = Color(hex: 0x353B80)

    /// Lueur de l'accent (ombres portées des anneaux et barres).
    static let lueur = Color(hex: 0x9184D9).opacity(0.45)
}

extension Color {
    /// Couleur sRGB depuis un littéral hexadécimal `0xRRGGBB`.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
