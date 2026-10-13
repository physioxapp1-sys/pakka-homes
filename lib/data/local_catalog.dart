/// The categories the home screen offers, and what tapping one means.
///
/// Only the grouping lives here. Everything inside a category - the tiles,
/// their pictures, names and rates - comes from the API, so adding a trade in
/// admin shows up without an app release. This list is the one thing that
/// does not: which categories get a tile on the home screen is a design
/// decision, not catalog data, and the home screen only offers four of the
/// eleven the backend carries.
class LocalCategory {
  const LocalCategory({
    required this.name,
    required this.slug,
    this.sellsProducts = false,
  });

  /// The label on the tile. The backend has its own name for the same row and
  /// is free to differ - the shop sheet says "Sanitary Ware" where the app
  /// says "Sanitaryware" - so this is what the customer sees on the way in.
  final String name;

  /// The backend's slug for the category, which is what the API is queried by.
  final String slug;

  /// True where the entries are aisles of products to buy rather than services
  /// to book. Changes what tapping one does.
  final bool sellsProducts;
}

const kServiceCategories = <LocalCategory>[
  LocalCategory(name: 'Grocery', slug: 'grocery', sellsProducts: true),
  LocalCategory(name: 'Construction', slug: 'construction'),
  LocalCategory(name: 'Electrical', slug: 'electrical'),
  LocalCategory(name: 'Cleaning', slug: 'cleaning'),
  LocalCategory(name: 'Mason', slug: 'mason'),
  LocalCategory(name: 'Appliance Repair', slug: 'appliance-repair'),
  LocalCategory(name: 'Plumbing', slug: 'plumbing'),
  LocalCategory(name: 'Painting', slug: 'painting'),
  LocalCategory(name: 'Carpenter', slug: 'carpenter'),
  LocalCategory(name: 'Waterproofing', slug: 'waterproofing'),
  LocalCategory(name: 'Interior', slug: 'interior'),
];
