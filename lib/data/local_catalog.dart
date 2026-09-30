/// The catalog bundled with the app.
///
/// This is what renders before (or instead of) a successful API call, so the
/// app is fully usable offline and on first launch. The server is the source
/// of truth for names, rates and ordering; `assetFolder` is the join key —
/// it matches `Category.image_key` on the backend.
class LocalCategory {
  const LocalCategory({
    required this.name,
    required this.slug,
    required this.assetFolder,
    required this.imageCount,
  });

  final String name;

  /// The backend's slug for this category, which it derives from the name in
  /// the spreadsheet. Those names are not always the app's label — the shop
  /// sheet says "Sanitary Ware" where the app says "Sanitaryware" — so this is
  /// stored explicitly rather than slugified from `name`.
  final String slug;

  /// Folder under assets/<vertical>/ holding this category's numbered images,
  /// and the value the backend stores in Category.image_key.
  final String assetFolder;

  /// How many numbered images ship for this category (1.png .. N.png).
  final int imageCount;

  String assetPathPrefix(String vertical) => 'assets/$vertical/$assetFolder';
}

const kServiceCategories = <LocalCategory>[
  LocalCategory(name: 'Construction', slug: 'construction', assetFolder: 'construction', imageCount: 12),
  LocalCategory(name: 'Electrical', slug: 'electrical', assetFolder: 'electrical', imageCount: 12),
  LocalCategory(name: 'Cleaning', slug: 'cleaning', assetFolder: 'cleaning', imageCount: 11),
  LocalCategory(name: 'Mason', slug: 'mason', assetFolder: 'mason', imageCount: 11),
  LocalCategory(name: 'Appliance Repair', slug: 'appliance-repair', assetFolder: 'appliance-repair', imageCount: 12),
  LocalCategory(name: 'Plumbing', slug: 'plumbing', assetFolder: 'plumbing', imageCount: 12),
  LocalCategory(name: 'Painting', slug: 'painting', assetFolder: 'painting', imageCount: 10),
  LocalCategory(name: 'Carpenter', slug: 'carpenter', assetFolder: 'carpenter', imageCount: 11),
  LocalCategory(name: 'Waterproofing', slug: 'waterproofing', assetFolder: 'waterproofing', imageCount: 10),
  LocalCategory(name: 'Interior', slug: 'interior', assetFolder: 'interior', imageCount: 16),
];

const kShopCategories = <LocalCategory>[
  LocalCategory(name: 'Cement', slug: 'cement', assetFolder: 'cement', imageCount: 6),
  LocalCategory(name: 'Electrical', slug: 'electrical', assetFolder: 'electricals', imageCount: 12),
  LocalCategory(name: 'Sanitaryware', slug: 'sanitary-ware', assetFolder: 'sanitaryware', imageCount: 15),
  LocalCategory(name: 'Tools', slug: 'tools', assetFolder: 'tools', imageCount: 12),
  LocalCategory(name: 'Steel', slug: 'steel', assetFolder: 'steel', imageCount: 13),
  LocalCategory(name: 'Paint', slug: 'paint', assetFolder: 'paint', imageCount: 12),
  LocalCategory(name: 'Hardware', slug: 'hardware', assetFolder: 'hardware', imageCount: 18),
  LocalCategory(name: 'Water Tanks', slug: 'water-tanks', assetFolder: 'watertanks', imageCount: 10),
  LocalCategory(name: 'Plumbing Materials', slug: 'plumbing-materials', assetFolder: 'plumbing', imageCount: 10),
  LocalCategory(name: 'Tiles', slug: 'tiles', assetFolder: 'tiles', imageCount: 9),
  LocalCategory(name: 'Roofing', slug: 'roofing', assetFolder: 'roofing', imageCount: 8),
  LocalCategory(name: 'Construction Chemicals', slug: 'construction-chemicals', assetFolder: 'construction-chemicals', imageCount: 8),
  LocalCategory(name: 'Safety', slug: 'safety', assetFolder: 'safety', imageCount: 7),
];
