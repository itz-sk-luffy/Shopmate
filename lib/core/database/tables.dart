import 'package:drift/drift.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  RealColumn get price => real()();
  RealColumn get gstRate => real().withDefault(const Constant(0.0))();
  TextColumn get unit => text().withDefault(const Constant('piece'))();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get barcode => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100).unique()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get iconName => text().nullable()();
}

class Units extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  BoolColumn get isDecimalAllowed => boolean().withDefault(const Constant(false))();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get phone => text().nullable()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Bills extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get billNumber => text().unique()();
  DateTimeColumn get date => dateTime()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get paymentMode => text().withDefault(const Constant('Cash'))();
  RealColumn get cashAmount => real().withDefault(const Constant(0.0))();
  RealColumn get digitalAmount => real().withDefault(const Constant(0.0))();
  RealColumn get changeTendered => real().withDefault(const Constant(0.0))();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get itemDiscountTotal => real().withDefault(const Constant(0.0))();
  RealColumn get billDiscountPercent => real().withDefault(const Constant(0.0))();
  RealColumn get billDiscountAmount => real().withDefault(const Constant(0.0))();
  TextColumn get gstType => text().withDefault(const Constant('exclusive'))();
  RealColumn get cgstTotal => real().withDefault(const Constant(0.0))();
  RealColumn get sgstTotal => real().withDefault(const Constant(0.0))();
  RealColumn get igstTotal => real().withDefault(const Constant(0.0))();
  RealColumn get roundOff => real().withDefault(const Constant(0.0))();
  RealColumn get grandTotal => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isHeld => boolean().withDefault(const Constant(false))();
  BoolColumn get isCreditPaid => boolean().withDefault(const Constant(false))();
  BoolColumn get isEdited => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class BillItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get billId => integer().references(Bills, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().nullable()();
  TextColumn get productName => text()();
  TextColumn get unit => text().withDefault(const Constant('piece'))();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  RealColumn get unitPrice => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get gstRate => real().withDefault(const Constant(0.0))();
  RealColumn get gstAmount => real().withDefault(const Constant(0.0))();
  RealColumn get taxableValue => real().withDefault(const Constant(0.0))();
  RealColumn get cgstAmount => real().withDefault(const Constant(0.0))();
  RealColumn get sgstAmount => real().withDefault(const Constant(0.0))();
  RealColumn get igstAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real()();
}

class BillEdits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get billId => integer().references(Bills, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get editedAt => dateTime().withDefault(currentDateAndTime)();
  RealColumn get previousTotal => real()();
  RealColumn get newTotal => real()();
  TextColumn get reasonNotes => text().nullable()();
  TextColumn get changesJson => text()();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  RealColumn get amount => real()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

class DayClosings extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get openingCash => real().withDefault(const Constant(0.0))();
  RealColumn get cashSales => real().withDefault(const Constant(0.0))();
  RealColumn get returnsAmount => real().withDefault(const Constant(0.0))();
  RealColumn get cashExpenses => real().withDefault(const Constant(0.0))();
  RealColumn get expectedCash => real().withDefault(const Constant(0.0))();
  RealColumn get countedCash => real().withDefault(const Constant(0.0))();
  RealColumn get difference => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get closedAt => dateTime().withDefault(currentDateAndTime)();
}

class StoreSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class ProductVariants extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
  TextColumn get variantName => text().withDefault(const Constant('Standard'))();
  RealColumn get price => real()();
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  TextColumn get sku => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class ProductBarcodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get variantId => integer().nullable().references(ProductVariants, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
  TextColumn get barcode => text().unique()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class UnmatchedScans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get barcode => text()();
  IntColumn get scanCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastScannedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
