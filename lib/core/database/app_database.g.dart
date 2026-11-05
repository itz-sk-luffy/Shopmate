// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'icon_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, colorHex, iconName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex']),
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_name']),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;
  final String? colorHex;
  final String? iconName;
  const Category(
      {required this.id, required this.name, this.colorHex, this.iconName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    if (!nullToAbsent || iconName != null) {
      map['icon_name'] = Variable<String>(iconName);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      iconName: iconName == null && nullToAbsent
          ? const Value.absent()
          : Value(iconName),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      iconName: serializer.fromJson<String?>(json['iconName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String?>(colorHex),
      'iconName': serializer.toJson<String?>(iconName),
    };
  }

  Category copyWith(
          {int? id,
          String? name,
          Value<String?> colorHex = const Value.absent(),
          Value<String?> iconName = const Value.absent()}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        colorHex: colorHex.present ? colorHex.value : this.colorHex,
        iconName: iconName.present ? iconName.value : this.iconName,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconName: $iconName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorHex, iconName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.iconName == this.iconName);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> colorHex;
  final Value<String?> iconName;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.iconName = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.colorHex = const Value.absent(),
    this.iconName = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<String>? iconName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (iconName != null) 'icon_name': iconName,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? colorHex,
      Value<String?>? iconName}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconName: $iconName')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _gstRateMeta =
      const VerificationMeta('gstRate');
  @override
  late final GeneratedColumn<double> gstRate = GeneratedColumn<double>(
      'gst_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('piece'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        price,
        gstRate,
        unit,
        categoryId,
        barcode,
        imagePath,
        isFavorite,
        isDeleted,
        deletedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<Product> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('gst_rate')) {
      context.handle(_gstRateMeta,
          gstRate.isAcceptableOrUnknown(data['gst_rate']!, _gstRateMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      gstRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}gst_rate'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String name;
  final double price;
  final double gstRate;
  final String unit;
  final int? categoryId;
  final String? barcode;
  final String? imagePath;
  final bool isFavorite;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Product(
      {required this.id,
      required this.name,
      required this.price,
      required this.gstRate,
      required this.unit,
      this.categoryId,
      this.barcode,
      this.imagePath,
      required this.isFavorite,
      required this.isDeleted,
      this.deletedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<double>(price);
    map['gst_rate'] = Variable<double>(gstRate);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      price: Value(price),
      gstRate: Value(gstRate),
      unit: Value(unit),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      isFavorite: Value(isFavorite),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<double>(json['price']),
      gstRate: serializer.fromJson<double>(json['gstRate']),
      unit: serializer.fromJson<String>(json['unit']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<double>(price),
      'gstRate': serializer.toJson<double>(gstRate),
      'unit': serializer.toJson<String>(unit),
      'categoryId': serializer.toJson<int?>(categoryId),
      'barcode': serializer.toJson<String?>(barcode),
      'imagePath': serializer.toJson<String?>(imagePath),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Product copyWith(
          {int? id,
          String? name,
          double? price,
          double? gstRate,
          String? unit,
          Value<int?> categoryId = const Value.absent(),
          Value<String?> barcode = const Value.absent(),
          Value<String?> imagePath = const Value.absent(),
          bool? isFavorite,
          bool? isDeleted,
          Value<DateTime?> deletedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
        gstRate: gstRate ?? this.gstRate,
        unit: unit ?? this.unit,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        barcode: barcode.present ? barcode.value : this.barcode,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        isFavorite: isFavorite ?? this.isFavorite,
        isDeleted: isDeleted ?? this.isDeleted,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      gstRate: data.gstRate.present ? data.gstRate.value : this.gstRate,
      unit: data.unit.present ? data.unit.value : this.unit,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('gstRate: $gstRate, ')
          ..write('unit: $unit, ')
          ..write('categoryId: $categoryId, ')
          ..write('barcode: $barcode, ')
          ..write('imagePath: $imagePath, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      price,
      gstRate,
      unit,
      categoryId,
      barcode,
      imagePath,
      isFavorite,
      isDeleted,
      deletedAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.price == this.price &&
          other.gstRate == this.gstRate &&
          other.unit == this.unit &&
          other.categoryId == this.categoryId &&
          other.barcode == this.barcode &&
          other.imagePath == this.imagePath &&
          other.isFavorite == this.isFavorite &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> price;
  final Value<double> gstRate;
  final Value<String> unit;
  final Value<int?> categoryId;
  final Value<String?> barcode;
  final Value<String?> imagePath;
  final Value<bool> isFavorite;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.gstRate = const Value.absent(),
    this.unit = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.barcode = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double price,
    this.gstRate = const Value.absent(),
    this.unit = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.barcode = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        price = Value(price);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? price,
    Expression<double>? gstRate,
    Expression<String>? unit,
    Expression<int>? categoryId,
    Expression<String>? barcode,
    Expression<String>? imagePath,
    Expression<bool>? isFavorite,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (gstRate != null) 'gst_rate': gstRate,
      if (unit != null) 'unit': unit,
      if (categoryId != null) 'category_id': categoryId,
      if (barcode != null) 'barcode': barcode,
      if (imagePath != null) 'image_path': imagePath,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProductsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double>? price,
      Value<double>? gstRate,
      Value<String>? unit,
      Value<int?>? categoryId,
      Value<String?>? barcode,
      Value<String?>? imagePath,
      Value<bool>? isFavorite,
      Value<bool>? isDeleted,
      Value<DateTime?>? deletedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      gstRate: gstRate ?? this.gstRate,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      barcode: barcode ?? this.barcode,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (gstRate.present) {
      map['gst_rate'] = Variable<double>(gstRate.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('gstRate: $gstRate, ')
          ..write('unit: $unit, ')
          ..write('categoryId: $categoryId, ')
          ..write('barcode: $barcode, ')
          ..write('imagePath: $imagePath, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $UnitsTable extends Units with TableInfo<$UnitsTable, Unit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDecimalAllowedMeta =
      const VerificationMeta('isDecimalAllowed');
  @override
  late final GeneratedColumn<bool> isDecimalAllowed = GeneratedColumn<bool>(
      'is_decimal_allowed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_decimal_allowed" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [id, code, name, isDecimalAllowed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'units';
  @override
  VerificationContext validateIntegrity(Insertable<Unit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_decimal_allowed')) {
      context.handle(
          _isDecimalAllowedMeta,
          isDecimalAllowed.isAcceptableOrUnknown(
              data['is_decimal_allowed']!, _isDecimalAllowedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Unit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Unit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isDecimalAllowed: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_decimal_allowed'])!,
    );
  }

  @override
  $UnitsTable createAlias(String alias) {
    return $UnitsTable(attachedDatabase, alias);
  }
}

class Unit extends DataClass implements Insertable<Unit> {
  final int id;
  final String code;
  final String name;
  final bool isDecimalAllowed;
  const Unit(
      {required this.id,
      required this.code,
      required this.name,
      required this.isDecimalAllowed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['is_decimal_allowed'] = Variable<bool>(isDecimalAllowed);
    return map;
  }

  UnitsCompanion toCompanion(bool nullToAbsent) {
    return UnitsCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      isDecimalAllowed: Value(isDecimalAllowed),
    );
  }

  factory Unit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Unit(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      isDecimalAllowed: serializer.fromJson<bool>(json['isDecimalAllowed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'isDecimalAllowed': serializer.toJson<bool>(isDecimalAllowed),
    };
  }

  Unit copyWith(
          {int? id, String? code, String? name, bool? isDecimalAllowed}) =>
      Unit(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        isDecimalAllowed: isDecimalAllowed ?? this.isDecimalAllowed,
      );
  Unit copyWithCompanion(UnitsCompanion data) {
    return Unit(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      isDecimalAllowed: data.isDecimalAllowed.present
          ? data.isDecimalAllowed.value
          : this.isDecimalAllowed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Unit(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('isDecimalAllowed: $isDecimalAllowed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, isDecimalAllowed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Unit &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.isDecimalAllowed == this.isDecimalAllowed);
}

class UnitsCompanion extends UpdateCompanion<Unit> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> name;
  final Value<bool> isDecimalAllowed;
  const UnitsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.isDecimalAllowed = const Value.absent(),
  });
  UnitsCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String name,
    this.isDecimalAllowed = const Value.absent(),
  })  : code = Value(code),
        name = Value(name);
  static Insertable<Unit> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<bool>? isDecimalAllowed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (isDecimalAllowed != null) 'is_decimal_allowed': isDecimalAllowed,
    });
  }

  UnitsCompanion copyWith(
      {Value<int>? id,
      Value<String>? code,
      Value<String>? name,
      Value<bool>? isDecimalAllowed}) {
    return UnitsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      isDecimalAllowed: isDecimalAllowed ?? this.isDecimalAllowed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDecimalAllowed.present) {
      map['is_decimal_allowed'] = Variable<bool>(isDecimalAllowed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('isDecimalAllowed: $isDecimalAllowed')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 150),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _balanceMeta =
      const VerificationMeta('balance');
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
      'balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, phone, balance, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(Insertable<Customer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('balance')) {
      context.handle(_balanceMeta,
          balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      balance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}balance'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final int id;
  final String name;
  final String? phone;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Customer(
      {required this.id,
      required this.name,
      this.phone,
      required this.balance,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['balance'] = Variable<double>(balance);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      balance: Value(balance),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      balance: serializer.fromJson<double>(json['balance']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'balance': serializer.toJson<double>(balance),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Customer copyWith(
          {int? id,
          String? name,
          Value<String?> phone = const Value.absent(),
          double? balance,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone.present ? phone.value : this.phone,
        balance: balance ?? this.balance,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      balance: data.balance.present ? data.balance.value : this.balance,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('balance: $balance, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, phone, balance, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.balance == this.balance &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<double> balance;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.balance = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CustomersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.balance = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Customer> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<double>? balance,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (balance != null) 'balance': balance,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CustomersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? phone,
      Value<double>? balance,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('balance: $balance, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BillsTable extends Bills with TableInfo<$BillsTable, Bill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _billNumberMeta =
      const VerificationMeta('billNumber');
  @override
  late final GeneratedColumn<String> billNumber = GeneratedColumn<String>(
      'bill_number', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES customers (id)'));
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerPhoneMeta =
      const VerificationMeta('customerPhone');
  @override
  late final GeneratedColumn<String> customerPhone = GeneratedColumn<String>(
      'customer_phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paymentModeMeta =
      const VerificationMeta('paymentMode');
  @override
  late final GeneratedColumn<String> paymentMode = GeneratedColumn<String>(
      'payment_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Cash'));
  static const VerificationMeta _cashAmountMeta =
      const VerificationMeta('cashAmount');
  @override
  late final GeneratedColumn<double> cashAmount = GeneratedColumn<double>(
      'cash_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _digitalAmountMeta =
      const VerificationMeta('digitalAmount');
  @override
  late final GeneratedColumn<double> digitalAmount = GeneratedColumn<double>(
      'digital_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _changeTenderedMeta =
      const VerificationMeta('changeTendered');
  @override
  late final GeneratedColumn<double> changeTendered = GeneratedColumn<double>(
      'change_tendered', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _itemDiscountTotalMeta =
      const VerificationMeta('itemDiscountTotal');
  @override
  late final GeneratedColumn<double> itemDiscountTotal =
      GeneratedColumn<double>('item_discount_total', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _billDiscountPercentMeta =
      const VerificationMeta('billDiscountPercent');
  @override
  late final GeneratedColumn<double> billDiscountPercent =
      GeneratedColumn<double>('bill_discount_percent', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _billDiscountAmountMeta =
      const VerificationMeta('billDiscountAmount');
  @override
  late final GeneratedColumn<double> billDiscountAmount =
      GeneratedColumn<double>('bill_discount_amount', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _gstTypeMeta =
      const VerificationMeta('gstType');
  @override
  late final GeneratedColumn<String> gstType = GeneratedColumn<String>(
      'gst_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('exclusive'));
  static const VerificationMeta _cgstTotalMeta =
      const VerificationMeta('cgstTotal');
  @override
  late final GeneratedColumn<double> cgstTotal = GeneratedColumn<double>(
      'cgst_total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _sgstTotalMeta =
      const VerificationMeta('sgstTotal');
  @override
  late final GeneratedColumn<double> sgstTotal = GeneratedColumn<double>(
      'sgst_total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _igstTotalMeta =
      const VerificationMeta('igstTotal');
  @override
  late final GeneratedColumn<double> igstTotal = GeneratedColumn<double>(
      'igst_total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _roundOffMeta =
      const VerificationMeta('roundOff');
  @override
  late final GeneratedColumn<double> roundOff = GeneratedColumn<double>(
      'round_off', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _grandTotalMeta =
      const VerificationMeta('grandTotal');
  @override
  late final GeneratedColumn<double> grandTotal = GeneratedColumn<double>(
      'grand_total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isHeldMeta = const VerificationMeta('isHeld');
  @override
  late final GeneratedColumn<bool> isHeld = GeneratedColumn<bool>(
      'is_held', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_held" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isCreditPaidMeta =
      const VerificationMeta('isCreditPaid');
  @override
  late final GeneratedColumn<bool> isCreditPaid = GeneratedColumn<bool>(
      'is_credit_paid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_credit_paid" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isEditedMeta =
      const VerificationMeta('isEdited');
  @override
  late final GeneratedColumn<bool> isEdited = GeneratedColumn<bool>(
      'is_edited', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_edited" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        billNumber,
        date,
        customerId,
        customerName,
        customerPhone,
        paymentMode,
        cashAmount,
        digitalAmount,
        changeTendered,
        subtotal,
        itemDiscountTotal,
        billDiscountPercent,
        billDiscountAmount,
        gstType,
        cgstTotal,
        sgstTotal,
        igstTotal,
        roundOff,
        grandTotal,
        notes,
        isHeld,
        isCreditPaid,
        isEdited,
        isDeleted,
        deletedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bills';
  @override
  VerificationContext validateIntegrity(Insertable<Bill> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bill_number')) {
      context.handle(
          _billNumberMeta,
          billNumber.isAcceptableOrUnknown(
              data['bill_number']!, _billNumberMeta));
    } else if (isInserting) {
      context.missing(_billNumberMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
    }
    if (data.containsKey('customer_phone')) {
      context.handle(
          _customerPhoneMeta,
          customerPhone.isAcceptableOrUnknown(
              data['customer_phone']!, _customerPhoneMeta));
    }
    if (data.containsKey('payment_mode')) {
      context.handle(
          _paymentModeMeta,
          paymentMode.isAcceptableOrUnknown(
              data['payment_mode']!, _paymentModeMeta));
    }
    if (data.containsKey('cash_amount')) {
      context.handle(
          _cashAmountMeta,
          cashAmount.isAcceptableOrUnknown(
              data['cash_amount']!, _cashAmountMeta));
    }
    if (data.containsKey('digital_amount')) {
      context.handle(
          _digitalAmountMeta,
          digitalAmount.isAcceptableOrUnknown(
              data['digital_amount']!, _digitalAmountMeta));
    }
    if (data.containsKey('change_tendered')) {
      context.handle(
          _changeTenderedMeta,
          changeTendered.isAcceptableOrUnknown(
              data['change_tendered']!, _changeTenderedMeta));
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    }
    if (data.containsKey('item_discount_total')) {
      context.handle(
          _itemDiscountTotalMeta,
          itemDiscountTotal.isAcceptableOrUnknown(
              data['item_discount_total']!, _itemDiscountTotalMeta));
    }
    if (data.containsKey('bill_discount_percent')) {
      context.handle(
          _billDiscountPercentMeta,
          billDiscountPercent.isAcceptableOrUnknown(
              data['bill_discount_percent']!, _billDiscountPercentMeta));
    }
    if (data.containsKey('bill_discount_amount')) {
      context.handle(
          _billDiscountAmountMeta,
          billDiscountAmount.isAcceptableOrUnknown(
              data['bill_discount_amount']!, _billDiscountAmountMeta));
    }
    if (data.containsKey('gst_type')) {
      context.handle(_gstTypeMeta,
          gstType.isAcceptableOrUnknown(data['gst_type']!, _gstTypeMeta));
    }
    if (data.containsKey('cgst_total')) {
      context.handle(_cgstTotalMeta,
          cgstTotal.isAcceptableOrUnknown(data['cgst_total']!, _cgstTotalMeta));
    }
    if (data.containsKey('sgst_total')) {
      context.handle(_sgstTotalMeta,
          sgstTotal.isAcceptableOrUnknown(data['sgst_total']!, _sgstTotalMeta));
    }
    if (data.containsKey('igst_total')) {
      context.handle(_igstTotalMeta,
          igstTotal.isAcceptableOrUnknown(data['igst_total']!, _igstTotalMeta));
    }
    if (data.containsKey('round_off')) {
      context.handle(_roundOffMeta,
          roundOff.isAcceptableOrUnknown(data['round_off']!, _roundOffMeta));
    }
    if (data.containsKey('grand_total')) {
      context.handle(
          _grandTotalMeta,
          grandTotal.isAcceptableOrUnknown(
              data['grand_total']!, _grandTotalMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_held')) {
      context.handle(_isHeldMeta,
          isHeld.isAcceptableOrUnknown(data['is_held']!, _isHeldMeta));
    }
    if (data.containsKey('is_credit_paid')) {
      context.handle(
          _isCreditPaidMeta,
          isCreditPaid.isAcceptableOrUnknown(
              data['is_credit_paid']!, _isCreditPaidMeta));
    }
    if (data.containsKey('is_edited')) {
      context.handle(_isEditedMeta,
          isEdited.isAcceptableOrUnknown(data['is_edited']!, _isEditedMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bill(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      billNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bill_number'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}customer_id']),
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name']),
      customerPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_phone']),
      paymentMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_mode'])!,
      cashAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cash_amount'])!,
      digitalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}digital_amount'])!,
      changeTendered: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}change_tendered'])!,
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
      itemDiscountTotal: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}item_discount_total'])!,
      billDiscountPercent: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}bill_discount_percent'])!,
      billDiscountAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}bill_discount_amount'])!,
      gstType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gst_type'])!,
      cgstTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cgst_total'])!,
      sgstTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sgst_total'])!,
      igstTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}igst_total'])!,
      roundOff: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}round_off'])!,
      grandTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}grand_total'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isHeld: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_held'])!,
      isCreditPaid: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_credit_paid'])!,
      isEdited: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_edited'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BillsTable createAlias(String alias) {
    return $BillsTable(attachedDatabase, alias);
  }
}

class Bill extends DataClass implements Insertable<Bill> {
  final int id;
  final String billNumber;
  final DateTime date;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final String paymentMode;
  final double cashAmount;
  final double digitalAmount;
  final double changeTendered;
  final double subtotal;
  final double itemDiscountTotal;
  final double billDiscountPercent;
  final double billDiscountAmount;
  final String gstType;
  final double cgstTotal;
  final double sgstTotal;
  final double igstTotal;
  final double roundOff;
  final double grandTotal;
  final String? notes;
  final bool isHeld;
  final bool isCreditPaid;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Bill(
      {required this.id,
      required this.billNumber,
      required this.date,
      this.customerId,
      this.customerName,
      this.customerPhone,
      required this.paymentMode,
      required this.cashAmount,
      required this.digitalAmount,
      required this.changeTendered,
      required this.subtotal,
      required this.itemDiscountTotal,
      required this.billDiscountPercent,
      required this.billDiscountAmount,
      required this.gstType,
      required this.cgstTotal,
      required this.sgstTotal,
      required this.igstTotal,
      required this.roundOff,
      required this.grandTotal,
      this.notes,
      required this.isHeld,
      required this.isCreditPaid,
      required this.isEdited,
      required this.isDeleted,
      this.deletedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bill_number'] = Variable<String>(billNumber);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<int>(customerId);
    }
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || customerPhone != null) {
      map['customer_phone'] = Variable<String>(customerPhone);
    }
    map['payment_mode'] = Variable<String>(paymentMode);
    map['cash_amount'] = Variable<double>(cashAmount);
    map['digital_amount'] = Variable<double>(digitalAmount);
    map['change_tendered'] = Variable<double>(changeTendered);
    map['subtotal'] = Variable<double>(subtotal);
    map['item_discount_total'] = Variable<double>(itemDiscountTotal);
    map['bill_discount_percent'] = Variable<double>(billDiscountPercent);
    map['bill_discount_amount'] = Variable<double>(billDiscountAmount);
    map['gst_type'] = Variable<String>(gstType);
    map['cgst_total'] = Variable<double>(cgstTotal);
    map['sgst_total'] = Variable<double>(sgstTotal);
    map['igst_total'] = Variable<double>(igstTotal);
    map['round_off'] = Variable<double>(roundOff);
    map['grand_total'] = Variable<double>(grandTotal);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_held'] = Variable<bool>(isHeld);
    map['is_credit_paid'] = Variable<bool>(isCreditPaid);
    map['is_edited'] = Variable<bool>(isEdited);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BillsCompanion toCompanion(bool nullToAbsent) {
    return BillsCompanion(
      id: Value(id),
      billNumber: Value(billNumber),
      date: Value(date),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      customerPhone: customerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(customerPhone),
      paymentMode: Value(paymentMode),
      cashAmount: Value(cashAmount),
      digitalAmount: Value(digitalAmount),
      changeTendered: Value(changeTendered),
      subtotal: Value(subtotal),
      itemDiscountTotal: Value(itemDiscountTotal),
      billDiscountPercent: Value(billDiscountPercent),
      billDiscountAmount: Value(billDiscountAmount),
      gstType: Value(gstType),
      cgstTotal: Value(cgstTotal),
      sgstTotal: Value(sgstTotal),
      igstTotal: Value(igstTotal),
      roundOff: Value(roundOff),
      grandTotal: Value(grandTotal),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isHeld: Value(isHeld),
      isCreditPaid: Value(isCreditPaid),
      isEdited: Value(isEdited),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Bill.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bill(
      id: serializer.fromJson<int>(json['id']),
      billNumber: serializer.fromJson<String>(json['billNumber']),
      date: serializer.fromJson<DateTime>(json['date']),
      customerId: serializer.fromJson<int?>(json['customerId']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      customerPhone: serializer.fromJson<String?>(json['customerPhone']),
      paymentMode: serializer.fromJson<String>(json['paymentMode']),
      cashAmount: serializer.fromJson<double>(json['cashAmount']),
      digitalAmount: serializer.fromJson<double>(json['digitalAmount']),
      changeTendered: serializer.fromJson<double>(json['changeTendered']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      itemDiscountTotal: serializer.fromJson<double>(json['itemDiscountTotal']),
      billDiscountPercent:
          serializer.fromJson<double>(json['billDiscountPercent']),
      billDiscountAmount:
          serializer.fromJson<double>(json['billDiscountAmount']),
      gstType: serializer.fromJson<String>(json['gstType']),
      cgstTotal: serializer.fromJson<double>(json['cgstTotal']),
      sgstTotal: serializer.fromJson<double>(json['sgstTotal']),
      igstTotal: serializer.fromJson<double>(json['igstTotal']),
      roundOff: serializer.fromJson<double>(json['roundOff']),
      grandTotal: serializer.fromJson<double>(json['grandTotal']),
      notes: serializer.fromJson<String?>(json['notes']),
      isHeld: serializer.fromJson<bool>(json['isHeld']),
      isCreditPaid: serializer.fromJson<bool>(json['isCreditPaid']),
      isEdited: serializer.fromJson<bool>(json['isEdited']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'billNumber': serializer.toJson<String>(billNumber),
      'date': serializer.toJson<DateTime>(date),
      'customerId': serializer.toJson<int?>(customerId),
      'customerName': serializer.toJson<String?>(customerName),
      'customerPhone': serializer.toJson<String?>(customerPhone),
      'paymentMode': serializer.toJson<String>(paymentMode),
      'cashAmount': serializer.toJson<double>(cashAmount),
      'digitalAmount': serializer.toJson<double>(digitalAmount),
      'changeTendered': serializer.toJson<double>(changeTendered),
      'subtotal': serializer.toJson<double>(subtotal),
      'itemDiscountTotal': serializer.toJson<double>(itemDiscountTotal),
      'billDiscountPercent': serializer.toJson<double>(billDiscountPercent),
      'billDiscountAmount': serializer.toJson<double>(billDiscountAmount),
      'gstType': serializer.toJson<String>(gstType),
      'cgstTotal': serializer.toJson<double>(cgstTotal),
      'sgstTotal': serializer.toJson<double>(sgstTotal),
      'igstTotal': serializer.toJson<double>(igstTotal),
      'roundOff': serializer.toJson<double>(roundOff),
      'grandTotal': serializer.toJson<double>(grandTotal),
      'notes': serializer.toJson<String?>(notes),
      'isHeld': serializer.toJson<bool>(isHeld),
      'isCreditPaid': serializer.toJson<bool>(isCreditPaid),
      'isEdited': serializer.toJson<bool>(isEdited),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Bill copyWith(
          {int? id,
          String? billNumber,
          DateTime? date,
          Value<int?> customerId = const Value.absent(),
          Value<String?> customerName = const Value.absent(),
          Value<String?> customerPhone = const Value.absent(),
          String? paymentMode,
          double? cashAmount,
          double? digitalAmount,
          double? changeTendered,
          double? subtotal,
          double? itemDiscountTotal,
          double? billDiscountPercent,
          double? billDiscountAmount,
          String? gstType,
          double? cgstTotal,
          double? sgstTotal,
          double? igstTotal,
          double? roundOff,
          double? grandTotal,
          Value<String?> notes = const Value.absent(),
          bool? isHeld,
          bool? isCreditPaid,
          bool? isEdited,
          bool? isDeleted,
          Value<DateTime?> deletedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Bill(
        id: id ?? this.id,
        billNumber: billNumber ?? this.billNumber,
        date: date ?? this.date,
        customerId: customerId.present ? customerId.value : this.customerId,
        customerName:
            customerName.present ? customerName.value : this.customerName,
        customerPhone:
            customerPhone.present ? customerPhone.value : this.customerPhone,
        paymentMode: paymentMode ?? this.paymentMode,
        cashAmount: cashAmount ?? this.cashAmount,
        digitalAmount: digitalAmount ?? this.digitalAmount,
        changeTendered: changeTendered ?? this.changeTendered,
        subtotal: subtotal ?? this.subtotal,
        itemDiscountTotal: itemDiscountTotal ?? this.itemDiscountTotal,
        billDiscountPercent: billDiscountPercent ?? this.billDiscountPercent,
        billDiscountAmount: billDiscountAmount ?? this.billDiscountAmount,
        gstType: gstType ?? this.gstType,
        cgstTotal: cgstTotal ?? this.cgstTotal,
        sgstTotal: sgstTotal ?? this.sgstTotal,
        igstTotal: igstTotal ?? this.igstTotal,
        roundOff: roundOff ?? this.roundOff,
        grandTotal: grandTotal ?? this.grandTotal,
        notes: notes.present ? notes.value : this.notes,
        isHeld: isHeld ?? this.isHeld,
        isCreditPaid: isCreditPaid ?? this.isCreditPaid,
        isEdited: isEdited ?? this.isEdited,
        isDeleted: isDeleted ?? this.isDeleted,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Bill copyWithCompanion(BillsCompanion data) {
    return Bill(
      id: data.id.present ? data.id.value : this.id,
      billNumber:
          data.billNumber.present ? data.billNumber.value : this.billNumber,
      date: data.date.present ? data.date.value : this.date,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerPhone: data.customerPhone.present
          ? data.customerPhone.value
          : this.customerPhone,
      paymentMode:
          data.paymentMode.present ? data.paymentMode.value : this.paymentMode,
      cashAmount:
          data.cashAmount.present ? data.cashAmount.value : this.cashAmount,
      digitalAmount: data.digitalAmount.present
          ? data.digitalAmount.value
          : this.digitalAmount,
      changeTendered: data.changeTendered.present
          ? data.changeTendered.value
          : this.changeTendered,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      itemDiscountTotal: data.itemDiscountTotal.present
          ? data.itemDiscountTotal.value
          : this.itemDiscountTotal,
      billDiscountPercent: data.billDiscountPercent.present
          ? data.billDiscountPercent.value
          : this.billDiscountPercent,
      billDiscountAmount: data.billDiscountAmount.present
          ? data.billDiscountAmount.value
          : this.billDiscountAmount,
      gstType: data.gstType.present ? data.gstType.value : this.gstType,
      cgstTotal: data.cgstTotal.present ? data.cgstTotal.value : this.cgstTotal,
      sgstTotal: data.sgstTotal.present ? data.sgstTotal.value : this.sgstTotal,
      igstTotal: data.igstTotal.present ? data.igstTotal.value : this.igstTotal,
      roundOff: data.roundOff.present ? data.roundOff.value : this.roundOff,
      grandTotal:
          data.grandTotal.present ? data.grandTotal.value : this.grandTotal,
      notes: data.notes.present ? data.notes.value : this.notes,
      isHeld: data.isHeld.present ? data.isHeld.value : this.isHeld,
      isCreditPaid: data.isCreditPaid.present
          ? data.isCreditPaid.value
          : this.isCreditPaid,
      isEdited: data.isEdited.present ? data.isEdited.value : this.isEdited,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bill(')
          ..write('id: $id, ')
          ..write('billNumber: $billNumber, ')
          ..write('date: $date, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('cashAmount: $cashAmount, ')
          ..write('digitalAmount: $digitalAmount, ')
          ..write('changeTendered: $changeTendered, ')
          ..write('subtotal: $subtotal, ')
          ..write('itemDiscountTotal: $itemDiscountTotal, ')
          ..write('billDiscountPercent: $billDiscountPercent, ')
          ..write('billDiscountAmount: $billDiscountAmount, ')
          ..write('gstType: $gstType, ')
          ..write('cgstTotal: $cgstTotal, ')
          ..write('sgstTotal: $sgstTotal, ')
          ..write('igstTotal: $igstTotal, ')
          ..write('roundOff: $roundOff, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('notes: $notes, ')
          ..write('isHeld: $isHeld, ')
          ..write('isCreditPaid: $isCreditPaid, ')
          ..write('isEdited: $isEdited, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        billNumber,
        date,
        customerId,
        customerName,
        customerPhone,
        paymentMode,
        cashAmount,
        digitalAmount,
        changeTendered,
        subtotal,
        itemDiscountTotal,
        billDiscountPercent,
        billDiscountAmount,
        gstType,
        cgstTotal,
        sgstTotal,
        igstTotal,
        roundOff,
        grandTotal,
        notes,
        isHeld,
        isCreditPaid,
        isEdited,
        isDeleted,
        deletedAt,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bill &&
          other.id == this.id &&
          other.billNumber == this.billNumber &&
          other.date == this.date &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.customerPhone == this.customerPhone &&
          other.paymentMode == this.paymentMode &&
          other.cashAmount == this.cashAmount &&
          other.digitalAmount == this.digitalAmount &&
          other.changeTendered == this.changeTendered &&
          other.subtotal == this.subtotal &&
          other.itemDiscountTotal == this.itemDiscountTotal &&
          other.billDiscountPercent == this.billDiscountPercent &&
          other.billDiscountAmount == this.billDiscountAmount &&
          other.gstType == this.gstType &&
          other.cgstTotal == this.cgstTotal &&
          other.sgstTotal == this.sgstTotal &&
          other.igstTotal == this.igstTotal &&
          other.roundOff == this.roundOff &&
          other.grandTotal == this.grandTotal &&
          other.notes == this.notes &&
          other.isHeld == this.isHeld &&
          other.isCreditPaid == this.isCreditPaid &&
          other.isEdited == this.isEdited &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BillsCompanion extends UpdateCompanion<Bill> {
  final Value<int> id;
  final Value<String> billNumber;
  final Value<DateTime> date;
  final Value<int?> customerId;
  final Value<String?> customerName;
  final Value<String?> customerPhone;
  final Value<String> paymentMode;
  final Value<double> cashAmount;
  final Value<double> digitalAmount;
  final Value<double> changeTendered;
  final Value<double> subtotal;
  final Value<double> itemDiscountTotal;
  final Value<double> billDiscountPercent;
  final Value<double> billDiscountAmount;
  final Value<String> gstType;
  final Value<double> cgstTotal;
  final Value<double> sgstTotal;
  final Value<double> igstTotal;
  final Value<double> roundOff;
  final Value<double> grandTotal;
  final Value<String?> notes;
  final Value<bool> isHeld;
  final Value<bool> isCreditPaid;
  final Value<bool> isEdited;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BillsCompanion({
    this.id = const Value.absent(),
    this.billNumber = const Value.absent(),
    this.date = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.paymentMode = const Value.absent(),
    this.cashAmount = const Value.absent(),
    this.digitalAmount = const Value.absent(),
    this.changeTendered = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.itemDiscountTotal = const Value.absent(),
    this.billDiscountPercent = const Value.absent(),
    this.billDiscountAmount = const Value.absent(),
    this.gstType = const Value.absent(),
    this.cgstTotal = const Value.absent(),
    this.sgstTotal = const Value.absent(),
    this.igstTotal = const Value.absent(),
    this.roundOff = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.notes = const Value.absent(),
    this.isHeld = const Value.absent(),
    this.isCreditPaid = const Value.absent(),
    this.isEdited = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BillsCompanion.insert({
    this.id = const Value.absent(),
    required String billNumber,
    required DateTime date,
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.paymentMode = const Value.absent(),
    this.cashAmount = const Value.absent(),
    this.digitalAmount = const Value.absent(),
    this.changeTendered = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.itemDiscountTotal = const Value.absent(),
    this.billDiscountPercent = const Value.absent(),
    this.billDiscountAmount = const Value.absent(),
    this.gstType = const Value.absent(),
    this.cgstTotal = const Value.absent(),
    this.sgstTotal = const Value.absent(),
    this.igstTotal = const Value.absent(),
    this.roundOff = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.notes = const Value.absent(),
    this.isHeld = const Value.absent(),
    this.isCreditPaid = const Value.absent(),
    this.isEdited = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : billNumber = Value(billNumber),
        date = Value(date);
  static Insertable<Bill> custom({
    Expression<int>? id,
    Expression<String>? billNumber,
    Expression<DateTime>? date,
    Expression<int>? customerId,
    Expression<String>? customerName,
    Expression<String>? customerPhone,
    Expression<String>? paymentMode,
    Expression<double>? cashAmount,
    Expression<double>? digitalAmount,
    Expression<double>? changeTendered,
    Expression<double>? subtotal,
    Expression<double>? itemDiscountTotal,
    Expression<double>? billDiscountPercent,
    Expression<double>? billDiscountAmount,
    Expression<String>? gstType,
    Expression<double>? cgstTotal,
    Expression<double>? sgstTotal,
    Expression<double>? igstTotal,
    Expression<double>? roundOff,
    Expression<double>? grandTotal,
    Expression<String>? notes,
    Expression<bool>? isHeld,
    Expression<bool>? isCreditPaid,
    Expression<bool>? isEdited,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billNumber != null) 'bill_number': billNumber,
      if (date != null) 'date': date,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (cashAmount != null) 'cash_amount': cashAmount,
      if (digitalAmount != null) 'digital_amount': digitalAmount,
      if (changeTendered != null) 'change_tendered': changeTendered,
      if (subtotal != null) 'subtotal': subtotal,
      if (itemDiscountTotal != null) 'item_discount_total': itemDiscountTotal,
      if (billDiscountPercent != null)
        'bill_discount_percent': billDiscountPercent,
      if (billDiscountAmount != null)
        'bill_discount_amount': billDiscountAmount,
      if (gstType != null) 'gst_type': gstType,
      if (cgstTotal != null) 'cgst_total': cgstTotal,
      if (sgstTotal != null) 'sgst_total': sgstTotal,
      if (igstTotal != null) 'igst_total': igstTotal,
      if (roundOff != null) 'round_off': roundOff,
      if (grandTotal != null) 'grand_total': grandTotal,
      if (notes != null) 'notes': notes,
      if (isHeld != null) 'is_held': isHeld,
      if (isCreditPaid != null) 'is_credit_paid': isCreditPaid,
      if (isEdited != null) 'is_edited': isEdited,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BillsCompanion copyWith(
      {Value<int>? id,
      Value<String>? billNumber,
      Value<DateTime>? date,
      Value<int?>? customerId,
      Value<String?>? customerName,
      Value<String?>? customerPhone,
      Value<String>? paymentMode,
      Value<double>? cashAmount,
      Value<double>? digitalAmount,
      Value<double>? changeTendered,
      Value<double>? subtotal,
      Value<double>? itemDiscountTotal,
      Value<double>? billDiscountPercent,
      Value<double>? billDiscountAmount,
      Value<String>? gstType,
      Value<double>? cgstTotal,
      Value<double>? sgstTotal,
      Value<double>? igstTotal,
      Value<double>? roundOff,
      Value<double>? grandTotal,
      Value<String?>? notes,
      Value<bool>? isHeld,
      Value<bool>? isCreditPaid,
      Value<bool>? isEdited,
      Value<bool>? isDeleted,
      Value<DateTime?>? deletedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return BillsCompanion(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      paymentMode: paymentMode ?? this.paymentMode,
      cashAmount: cashAmount ?? this.cashAmount,
      digitalAmount: digitalAmount ?? this.digitalAmount,
      changeTendered: changeTendered ?? this.changeTendered,
      subtotal: subtotal ?? this.subtotal,
      itemDiscountTotal: itemDiscountTotal ?? this.itemDiscountTotal,
      billDiscountPercent: billDiscountPercent ?? this.billDiscountPercent,
      billDiscountAmount: billDiscountAmount ?? this.billDiscountAmount,
      gstType: gstType ?? this.gstType,
      cgstTotal: cgstTotal ?? this.cgstTotal,
      sgstTotal: sgstTotal ?? this.sgstTotal,
      igstTotal: igstTotal ?? this.igstTotal,
      roundOff: roundOff ?? this.roundOff,
      grandTotal: grandTotal ?? this.grandTotal,
      notes: notes ?? this.notes,
      isHeld: isHeld ?? this.isHeld,
      isCreditPaid: isCreditPaid ?? this.isCreditPaid,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (billNumber.present) {
      map['bill_number'] = Variable<String>(billNumber.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerPhone.present) {
      map['customer_phone'] = Variable<String>(customerPhone.value);
    }
    if (paymentMode.present) {
      map['payment_mode'] = Variable<String>(paymentMode.value);
    }
    if (cashAmount.present) {
      map['cash_amount'] = Variable<double>(cashAmount.value);
    }
    if (digitalAmount.present) {
      map['digital_amount'] = Variable<double>(digitalAmount.value);
    }
    if (changeTendered.present) {
      map['change_tendered'] = Variable<double>(changeTendered.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (itemDiscountTotal.present) {
      map['item_discount_total'] = Variable<double>(itemDiscountTotal.value);
    }
    if (billDiscountPercent.present) {
      map['bill_discount_percent'] =
          Variable<double>(billDiscountPercent.value);
    }
    if (billDiscountAmount.present) {
      map['bill_discount_amount'] = Variable<double>(billDiscountAmount.value);
    }
    if (gstType.present) {
      map['gst_type'] = Variable<String>(gstType.value);
    }
    if (cgstTotal.present) {
      map['cgst_total'] = Variable<double>(cgstTotal.value);
    }
    if (sgstTotal.present) {
      map['sgst_total'] = Variable<double>(sgstTotal.value);
    }
    if (igstTotal.present) {
      map['igst_total'] = Variable<double>(igstTotal.value);
    }
    if (roundOff.present) {
      map['round_off'] = Variable<double>(roundOff.value);
    }
    if (grandTotal.present) {
      map['grand_total'] = Variable<double>(grandTotal.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isHeld.present) {
      map['is_held'] = Variable<bool>(isHeld.value);
    }
    if (isCreditPaid.present) {
      map['is_credit_paid'] = Variable<bool>(isCreditPaid.value);
    }
    if (isEdited.present) {
      map['is_edited'] = Variable<bool>(isEdited.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillsCompanion(')
          ..write('id: $id, ')
          ..write('billNumber: $billNumber, ')
          ..write('date: $date, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('cashAmount: $cashAmount, ')
          ..write('digitalAmount: $digitalAmount, ')
          ..write('changeTendered: $changeTendered, ')
          ..write('subtotal: $subtotal, ')
          ..write('itemDiscountTotal: $itemDiscountTotal, ')
          ..write('billDiscountPercent: $billDiscountPercent, ')
          ..write('billDiscountAmount: $billDiscountAmount, ')
          ..write('gstType: $gstType, ')
          ..write('cgstTotal: $cgstTotal, ')
          ..write('sgstTotal: $sgstTotal, ')
          ..write('igstTotal: $igstTotal, ')
          ..write('roundOff: $roundOff, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('notes: $notes, ')
          ..write('isHeld: $isHeld, ')
          ..write('isCreditPaid: $isCreditPaid, ')
          ..write('isEdited: $isEdited, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BillItemsTable extends BillItems
    with TableInfo<$BillItemsTable, BillItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<int> billId = GeneratedColumn<int>(
      'bill_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES bills (id) ON DELETE CASCADE'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('piece'));
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _unitPriceMeta =
      const VerificationMeta('unitPrice');
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
      'unit_price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _discountAmountMeta =
      const VerificationMeta('discountAmount');
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
      'discount_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _gstRateMeta =
      const VerificationMeta('gstRate');
  @override
  late final GeneratedColumn<double> gstRate = GeneratedColumn<double>(
      'gst_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _gstAmountMeta =
      const VerificationMeta('gstAmount');
  @override
  late final GeneratedColumn<double> gstAmount = GeneratedColumn<double>(
      'gst_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _taxableValueMeta =
      const VerificationMeta('taxableValue');
  @override
  late final GeneratedColumn<double> taxableValue = GeneratedColumn<double>(
      'taxable_value', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _cgstAmountMeta =
      const VerificationMeta('cgstAmount');
  @override
  late final GeneratedColumn<double> cgstAmount = GeneratedColumn<double>(
      'cgst_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _sgstAmountMeta =
      const VerificationMeta('sgstAmount');
  @override
  late final GeneratedColumn<double> sgstAmount = GeneratedColumn<double>(
      'sgst_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _igstAmountMeta =
      const VerificationMeta('igstAmount');
  @override
  late final GeneratedColumn<double> igstAmount = GeneratedColumn<double>(
      'igst_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        billId,
        productId,
        productName,
        unit,
        quantity,
        unitPrice,
        discountAmount,
        gstRate,
        gstAmount,
        taxableValue,
        cgstAmount,
        sgstAmount,
        igstAmount,
        totalAmount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bill_items';
  @override
  VerificationContext validateIntegrity(Insertable<BillItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bill_id')) {
      context.handle(_billIdMeta,
          billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta));
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('unit_price')) {
      context.handle(_unitPriceMeta,
          unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta));
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
          _discountAmountMeta,
          discountAmount.isAcceptableOrUnknown(
              data['discount_amount']!, _discountAmountMeta));
    }
    if (data.containsKey('gst_rate')) {
      context.handle(_gstRateMeta,
          gstRate.isAcceptableOrUnknown(data['gst_rate']!, _gstRateMeta));
    }
    if (data.containsKey('gst_amount')) {
      context.handle(_gstAmountMeta,
          gstAmount.isAcceptableOrUnknown(data['gst_amount']!, _gstAmountMeta));
    }
    if (data.containsKey('taxable_value')) {
      context.handle(
          _taxableValueMeta,
          taxableValue.isAcceptableOrUnknown(
              data['taxable_value']!, _taxableValueMeta));
    }
    if (data.containsKey('cgst_amount')) {
      context.handle(
          _cgstAmountMeta,
          cgstAmount.isAcceptableOrUnknown(
              data['cgst_amount']!, _cgstAmountMeta));
    }
    if (data.containsKey('sgst_amount')) {
      context.handle(
          _sgstAmountMeta,
          sgstAmount.isAcceptableOrUnknown(
              data['sgst_amount']!, _sgstAmountMeta));
    }
    if (data.containsKey('igst_amount')) {
      context.handle(
          _igstAmountMeta,
          igstAmount.isAcceptableOrUnknown(
              data['igst_amount']!, _igstAmountMeta));
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      billId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bill_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id']),
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      unitPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unit_price'])!,
      discountAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}discount_amount'])!,
      gstRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}gst_rate'])!,
      gstAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}gst_amount'])!,
      taxableValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}taxable_value'])!,
      cgstAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cgst_amount'])!,
      sgstAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sgst_amount'])!,
      igstAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}igst_amount'])!,
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_amount'])!,
    );
  }

  @override
  $BillItemsTable createAlias(String alias) {
    return $BillItemsTable(attachedDatabase, alias);
  }
}

class BillItem extends DataClass implements Insertable<BillItem> {
  final int id;
  final int billId;
  final int? productId;
  final String productName;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double discountAmount;
  final double gstRate;
  final double gstAmount;
  final double taxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalAmount;
  const BillItem(
      {required this.id,
      required this.billId,
      this.productId,
      required this.productName,
      required this.unit,
      required this.quantity,
      required this.unitPrice,
      required this.discountAmount,
      required this.gstRate,
      required this.gstAmount,
      required this.taxableValue,
      required this.cgstAmount,
      required this.sgstAmount,
      required this.igstAmount,
      required this.totalAmount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bill_id'] = Variable<int>(billId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<int>(productId);
    }
    map['product_name'] = Variable<String>(productName);
    map['unit'] = Variable<String>(unit);
    map['quantity'] = Variable<double>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['gst_rate'] = Variable<double>(gstRate);
    map['gst_amount'] = Variable<double>(gstAmount);
    map['taxable_value'] = Variable<double>(taxableValue);
    map['cgst_amount'] = Variable<double>(cgstAmount);
    map['sgst_amount'] = Variable<double>(sgstAmount);
    map['igst_amount'] = Variable<double>(igstAmount);
    map['total_amount'] = Variable<double>(totalAmount);
    return map;
  }

  BillItemsCompanion toCompanion(bool nullToAbsent) {
    return BillItemsCompanion(
      id: Value(id),
      billId: Value(billId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      productName: Value(productName),
      unit: Value(unit),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      discountAmount: Value(discountAmount),
      gstRate: Value(gstRate),
      gstAmount: Value(gstAmount),
      taxableValue: Value(taxableValue),
      cgstAmount: Value(cgstAmount),
      sgstAmount: Value(sgstAmount),
      igstAmount: Value(igstAmount),
      totalAmount: Value(totalAmount),
    );
  }

  factory BillItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillItem(
      id: serializer.fromJson<int>(json['id']),
      billId: serializer.fromJson<int>(json['billId']),
      productId: serializer.fromJson<int?>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      unit: serializer.fromJson<String>(json['unit']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      gstRate: serializer.fromJson<double>(json['gstRate']),
      gstAmount: serializer.fromJson<double>(json['gstAmount']),
      taxableValue: serializer.fromJson<double>(json['taxableValue']),
      cgstAmount: serializer.fromJson<double>(json['cgstAmount']),
      sgstAmount: serializer.fromJson<double>(json['sgstAmount']),
      igstAmount: serializer.fromJson<double>(json['igstAmount']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'billId': serializer.toJson<int>(billId),
      'productId': serializer.toJson<int?>(productId),
      'productName': serializer.toJson<String>(productName),
      'unit': serializer.toJson<String>(unit),
      'quantity': serializer.toJson<double>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'gstRate': serializer.toJson<double>(gstRate),
      'gstAmount': serializer.toJson<double>(gstAmount),
      'taxableValue': serializer.toJson<double>(taxableValue),
      'cgstAmount': serializer.toJson<double>(cgstAmount),
      'sgstAmount': serializer.toJson<double>(sgstAmount),
      'igstAmount': serializer.toJson<double>(igstAmount),
      'totalAmount': serializer.toJson<double>(totalAmount),
    };
  }

  BillItem copyWith(
          {int? id,
          int? billId,
          Value<int?> productId = const Value.absent(),
          String? productName,
          String? unit,
          double? quantity,
          double? unitPrice,
          double? discountAmount,
          double? gstRate,
          double? gstAmount,
          double? taxableValue,
          double? cgstAmount,
          double? sgstAmount,
          double? igstAmount,
          double? totalAmount}) =>
      BillItem(
        id: id ?? this.id,
        billId: billId ?? this.billId,
        productId: productId.present ? productId.value : this.productId,
        productName: productName ?? this.productName,
        unit: unit ?? this.unit,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        discountAmount: discountAmount ?? this.discountAmount,
        gstRate: gstRate ?? this.gstRate,
        gstAmount: gstAmount ?? this.gstAmount,
        taxableValue: taxableValue ?? this.taxableValue,
        cgstAmount: cgstAmount ?? this.cgstAmount,
        sgstAmount: sgstAmount ?? this.sgstAmount,
        igstAmount: igstAmount ?? this.igstAmount,
        totalAmount: totalAmount ?? this.totalAmount,
      );
  BillItem copyWithCompanion(BillItemsCompanion data) {
    return BillItem(
      id: data.id.present ? data.id.value : this.id,
      billId: data.billId.present ? data.billId.value : this.billId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      unit: data.unit.present ? data.unit.value : this.unit,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      gstRate: data.gstRate.present ? data.gstRate.value : this.gstRate,
      gstAmount: data.gstAmount.present ? data.gstAmount.value : this.gstAmount,
      taxableValue: data.taxableValue.present
          ? data.taxableValue.value
          : this.taxableValue,
      cgstAmount:
          data.cgstAmount.present ? data.cgstAmount.value : this.cgstAmount,
      sgstAmount:
          data.sgstAmount.present ? data.sgstAmount.value : this.sgstAmount,
      igstAmount:
          data.igstAmount.present ? data.igstAmount.value : this.igstAmount,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillItem(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('unit: $unit, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('gstRate: $gstRate, ')
          ..write('gstAmount: $gstAmount, ')
          ..write('taxableValue: $taxableValue, ')
          ..write('cgstAmount: $cgstAmount, ')
          ..write('sgstAmount: $sgstAmount, ')
          ..write('igstAmount: $igstAmount, ')
          ..write('totalAmount: $totalAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      billId,
      productId,
      productName,
      unit,
      quantity,
      unitPrice,
      discountAmount,
      gstRate,
      gstAmount,
      taxableValue,
      cgstAmount,
      sgstAmount,
      igstAmount,
      totalAmount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillItem &&
          other.id == this.id &&
          other.billId == this.billId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.unit == this.unit &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.discountAmount == this.discountAmount &&
          other.gstRate == this.gstRate &&
          other.gstAmount == this.gstAmount &&
          other.taxableValue == this.taxableValue &&
          other.cgstAmount == this.cgstAmount &&
          other.sgstAmount == this.sgstAmount &&
          other.igstAmount == this.igstAmount &&
          other.totalAmount == this.totalAmount);
}

class BillItemsCompanion extends UpdateCompanion<BillItem> {
  final Value<int> id;
  final Value<int> billId;
  final Value<int?> productId;
  final Value<String> productName;
  final Value<String> unit;
  final Value<double> quantity;
  final Value<double> unitPrice;
  final Value<double> discountAmount;
  final Value<double> gstRate;
  final Value<double> gstAmount;
  final Value<double> taxableValue;
  final Value<double> cgstAmount;
  final Value<double> sgstAmount;
  final Value<double> igstAmount;
  final Value<double> totalAmount;
  const BillItemsCompanion({
    this.id = const Value.absent(),
    this.billId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.unit = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.gstRate = const Value.absent(),
    this.gstAmount = const Value.absent(),
    this.taxableValue = const Value.absent(),
    this.cgstAmount = const Value.absent(),
    this.sgstAmount = const Value.absent(),
    this.igstAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
  });
  BillItemsCompanion.insert({
    this.id = const Value.absent(),
    required int billId,
    this.productId = const Value.absent(),
    required String productName,
    this.unit = const Value.absent(),
    this.quantity = const Value.absent(),
    required double unitPrice,
    this.discountAmount = const Value.absent(),
    this.gstRate = const Value.absent(),
    this.gstAmount = const Value.absent(),
    this.taxableValue = const Value.absent(),
    this.cgstAmount = const Value.absent(),
    this.sgstAmount = const Value.absent(),
    this.igstAmount = const Value.absent(),
    required double totalAmount,
  })  : billId = Value(billId),
        productName = Value(productName),
        unitPrice = Value(unitPrice),
        totalAmount = Value(totalAmount);
  static Insertable<BillItem> custom({
    Expression<int>? id,
    Expression<int>? billId,
    Expression<int>? productId,
    Expression<String>? productName,
    Expression<String>? unit,
    Expression<double>? quantity,
    Expression<double>? unitPrice,
    Expression<double>? discountAmount,
    Expression<double>? gstRate,
    Expression<double>? gstAmount,
    Expression<double>? taxableValue,
    Expression<double>? cgstAmount,
    Expression<double>? sgstAmount,
    Expression<double>? igstAmount,
    Expression<double>? totalAmount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (unit != null) 'unit': unit,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (gstRate != null) 'gst_rate': gstRate,
      if (gstAmount != null) 'gst_amount': gstAmount,
      if (taxableValue != null) 'taxable_value': taxableValue,
      if (cgstAmount != null) 'cgst_amount': cgstAmount,
      if (sgstAmount != null) 'sgst_amount': sgstAmount,
      if (igstAmount != null) 'igst_amount': igstAmount,
      if (totalAmount != null) 'total_amount': totalAmount,
    });
  }

  BillItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? billId,
      Value<int?>? productId,
      Value<String>? productName,
      Value<String>? unit,
      Value<double>? quantity,
      Value<double>? unitPrice,
      Value<double>? discountAmount,
      Value<double>? gstRate,
      Value<double>? gstAmount,
      Value<double>? taxableValue,
      Value<double>? cgstAmount,
      Value<double>? sgstAmount,
      Value<double>? igstAmount,
      Value<double>? totalAmount}) {
    return BillItemsCompanion(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      gstRate: gstRate ?? this.gstRate,
      gstAmount: gstAmount ?? this.gstAmount,
      taxableValue: taxableValue ?? this.taxableValue,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<int>(billId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (gstRate.present) {
      map['gst_rate'] = Variable<double>(gstRate.value);
    }
    if (gstAmount.present) {
      map['gst_amount'] = Variable<double>(gstAmount.value);
    }
    if (taxableValue.present) {
      map['taxable_value'] = Variable<double>(taxableValue.value);
    }
    if (cgstAmount.present) {
      map['cgst_amount'] = Variable<double>(cgstAmount.value);
    }
    if (sgstAmount.present) {
      map['sgst_amount'] = Variable<double>(sgstAmount.value);
    }
    if (igstAmount.present) {
      map['igst_amount'] = Variable<double>(igstAmount.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillItemsCompanion(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('unit: $unit, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('gstRate: $gstRate, ')
          ..write('gstAmount: $gstAmount, ')
          ..write('taxableValue: $taxableValue, ')
          ..write('cgstAmount: $cgstAmount, ')
          ..write('sgstAmount: $sgstAmount, ')
          ..write('igstAmount: $igstAmount, ')
          ..write('totalAmount: $totalAmount')
          ..write(')'))
        .toString();
  }
}

class $BillEditsTable extends BillEdits
    with TableInfo<$BillEditsTable, BillEdit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillEditsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<int> billId = GeneratedColumn<int>(
      'bill_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES bills (id) ON DELETE CASCADE'));
  static const VerificationMeta _editedAtMeta =
      const VerificationMeta('editedAt');
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
      'edited_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _previousTotalMeta =
      const VerificationMeta('previousTotal');
  @override
  late final GeneratedColumn<double> previousTotal = GeneratedColumn<double>(
      'previous_total', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _newTotalMeta =
      const VerificationMeta('newTotal');
  @override
  late final GeneratedColumn<double> newTotal = GeneratedColumn<double>(
      'new_total', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _reasonNotesMeta =
      const VerificationMeta('reasonNotes');
  @override
  late final GeneratedColumn<String> reasonNotes = GeneratedColumn<String>(
      'reason_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _changesJsonMeta =
      const VerificationMeta('changesJson');
  @override
  late final GeneratedColumn<String> changesJson = GeneratedColumn<String>(
      'changes_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, billId, editedAt, previousTotal, newTotal, reasonNotes, changesJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bill_edits';
  @override
  VerificationContext validateIntegrity(Insertable<BillEdit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bill_id')) {
      context.handle(_billIdMeta,
          billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta));
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(_editedAtMeta,
          editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta));
    }
    if (data.containsKey('previous_total')) {
      context.handle(
          _previousTotalMeta,
          previousTotal.isAcceptableOrUnknown(
              data['previous_total']!, _previousTotalMeta));
    } else if (isInserting) {
      context.missing(_previousTotalMeta);
    }
    if (data.containsKey('new_total')) {
      context.handle(_newTotalMeta,
          newTotal.isAcceptableOrUnknown(data['new_total']!, _newTotalMeta));
    } else if (isInserting) {
      context.missing(_newTotalMeta);
    }
    if (data.containsKey('reason_notes')) {
      context.handle(
          _reasonNotesMeta,
          reasonNotes.isAcceptableOrUnknown(
              data['reason_notes']!, _reasonNotesMeta));
    }
    if (data.containsKey('changes_json')) {
      context.handle(
          _changesJsonMeta,
          changesJson.isAcceptableOrUnknown(
              data['changes_json']!, _changesJsonMeta));
    } else if (isInserting) {
      context.missing(_changesJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillEdit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillEdit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      billId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bill_id'])!,
      editedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}edited_at'])!,
      previousTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}previous_total'])!,
      newTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}new_total'])!,
      reasonNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason_notes']),
      changesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}changes_json'])!,
    );
  }

  @override
  $BillEditsTable createAlias(String alias) {
    return $BillEditsTable(attachedDatabase, alias);
  }
}

class BillEdit extends DataClass implements Insertable<BillEdit> {
  final int id;
  final int billId;
  final DateTime editedAt;
  final double previousTotal;
  final double newTotal;
  final String? reasonNotes;
  final String changesJson;
  const BillEdit(
      {required this.id,
      required this.billId,
      required this.editedAt,
      required this.previousTotal,
      required this.newTotal,
      this.reasonNotes,
      required this.changesJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bill_id'] = Variable<int>(billId);
    map['edited_at'] = Variable<DateTime>(editedAt);
    map['previous_total'] = Variable<double>(previousTotal);
    map['new_total'] = Variable<double>(newTotal);
    if (!nullToAbsent || reasonNotes != null) {
      map['reason_notes'] = Variable<String>(reasonNotes);
    }
    map['changes_json'] = Variable<String>(changesJson);
    return map;
  }

  BillEditsCompanion toCompanion(bool nullToAbsent) {
    return BillEditsCompanion(
      id: Value(id),
      billId: Value(billId),
      editedAt: Value(editedAt),
      previousTotal: Value(previousTotal),
      newTotal: Value(newTotal),
      reasonNotes: reasonNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(reasonNotes),
      changesJson: Value(changesJson),
    );
  }

  factory BillEdit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillEdit(
      id: serializer.fromJson<int>(json['id']),
      billId: serializer.fromJson<int>(json['billId']),
      editedAt: serializer.fromJson<DateTime>(json['editedAt']),
      previousTotal: serializer.fromJson<double>(json['previousTotal']),
      newTotal: serializer.fromJson<double>(json['newTotal']),
      reasonNotes: serializer.fromJson<String?>(json['reasonNotes']),
      changesJson: serializer.fromJson<String>(json['changesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'billId': serializer.toJson<int>(billId),
      'editedAt': serializer.toJson<DateTime>(editedAt),
      'previousTotal': serializer.toJson<double>(previousTotal),
      'newTotal': serializer.toJson<double>(newTotal),
      'reasonNotes': serializer.toJson<String?>(reasonNotes),
      'changesJson': serializer.toJson<String>(changesJson),
    };
  }

  BillEdit copyWith(
          {int? id,
          int? billId,
          DateTime? editedAt,
          double? previousTotal,
          double? newTotal,
          Value<String?> reasonNotes = const Value.absent(),
          String? changesJson}) =>
      BillEdit(
        id: id ?? this.id,
        billId: billId ?? this.billId,
        editedAt: editedAt ?? this.editedAt,
        previousTotal: previousTotal ?? this.previousTotal,
        newTotal: newTotal ?? this.newTotal,
        reasonNotes: reasonNotes.present ? reasonNotes.value : this.reasonNotes,
        changesJson: changesJson ?? this.changesJson,
      );
  BillEdit copyWithCompanion(BillEditsCompanion data) {
    return BillEdit(
      id: data.id.present ? data.id.value : this.id,
      billId: data.billId.present ? data.billId.value : this.billId,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      previousTotal: data.previousTotal.present
          ? data.previousTotal.value
          : this.previousTotal,
      newTotal: data.newTotal.present ? data.newTotal.value : this.newTotal,
      reasonNotes:
          data.reasonNotes.present ? data.reasonNotes.value : this.reasonNotes,
      changesJson:
          data.changesJson.present ? data.changesJson.value : this.changesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillEdit(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('editedAt: $editedAt, ')
          ..write('previousTotal: $previousTotal, ')
          ..write('newTotal: $newTotal, ')
          ..write('reasonNotes: $reasonNotes, ')
          ..write('changesJson: $changesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, billId, editedAt, previousTotal, newTotal, reasonNotes, changesJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillEdit &&
          other.id == this.id &&
          other.billId == this.billId &&
          other.editedAt == this.editedAt &&
          other.previousTotal == this.previousTotal &&
          other.newTotal == this.newTotal &&
          other.reasonNotes == this.reasonNotes &&
          other.changesJson == this.changesJson);
}

class BillEditsCompanion extends UpdateCompanion<BillEdit> {
  final Value<int> id;
  final Value<int> billId;
  final Value<DateTime> editedAt;
  final Value<double> previousTotal;
  final Value<double> newTotal;
  final Value<String?> reasonNotes;
  final Value<String> changesJson;
  const BillEditsCompanion({
    this.id = const Value.absent(),
    this.billId = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.previousTotal = const Value.absent(),
    this.newTotal = const Value.absent(),
    this.reasonNotes = const Value.absent(),
    this.changesJson = const Value.absent(),
  });
  BillEditsCompanion.insert({
    this.id = const Value.absent(),
    required int billId,
    this.editedAt = const Value.absent(),
    required double previousTotal,
    required double newTotal,
    this.reasonNotes = const Value.absent(),
    required String changesJson,
  })  : billId = Value(billId),
        previousTotal = Value(previousTotal),
        newTotal = Value(newTotal),
        changesJson = Value(changesJson);
  static Insertable<BillEdit> custom({
    Expression<int>? id,
    Expression<int>? billId,
    Expression<DateTime>? editedAt,
    Expression<double>? previousTotal,
    Expression<double>? newTotal,
    Expression<String>? reasonNotes,
    Expression<String>? changesJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      if (editedAt != null) 'edited_at': editedAt,
      if (previousTotal != null) 'previous_total': previousTotal,
      if (newTotal != null) 'new_total': newTotal,
      if (reasonNotes != null) 'reason_notes': reasonNotes,
      if (changesJson != null) 'changes_json': changesJson,
    });
  }

  BillEditsCompanion copyWith(
      {Value<int>? id,
      Value<int>? billId,
      Value<DateTime>? editedAt,
      Value<double>? previousTotal,
      Value<double>? newTotal,
      Value<String?>? reasonNotes,
      Value<String>? changesJson}) {
    return BillEditsCompanion(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      editedAt: editedAt ?? this.editedAt,
      previousTotal: previousTotal ?? this.previousTotal,
      newTotal: newTotal ?? this.newTotal,
      reasonNotes: reasonNotes ?? this.reasonNotes,
      changesJson: changesJson ?? this.changesJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<int>(billId.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    if (previousTotal.present) {
      map['previous_total'] = Variable<double>(previousTotal.value);
    }
    if (newTotal.present) {
      map['new_total'] = Variable<double>(newTotal.value);
    }
    if (reasonNotes.present) {
      map['reason_notes'] = Variable<String>(reasonNotes.value);
    }
    if (changesJson.present) {
      map['changes_json'] = Variable<String>(changesJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillEditsCompanion(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('editedAt: $editedAt, ')
          ..write('previousTotal: $previousTotal, ')
          ..write('newTotal: $newTotal, ')
          ..write('reasonNotes: $reasonNotes, ')
          ..write('changesJson: $changesJson')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('General'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, amount, category, date, notes, isDeleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(Insertable<Expense> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final int id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final bool isDeleted;
  const Expense(
      {required this.id,
      required this.title,
      required this.amount,
      required this.category,
      required this.date,
      this.notes,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['amount'] = Variable<double>(amount);
    map['category'] = Variable<String>(category);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      title: Value(title),
      amount: Value(amount),
      category: Value(category),
      date: Value(date),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isDeleted: Value(isDeleted),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      amount: serializer.fromJson<double>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      date: serializer.fromJson<DateTime>(json['date']),
      notes: serializer.fromJson<String?>(json['notes']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'amount': serializer.toJson<double>(amount),
      'category': serializer.toJson<String>(category),
      'date': serializer.toJson<DateTime>(date),
      'notes': serializer.toJson<String?>(notes),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Expense copyWith(
          {int? id,
          String? title,
          double? amount,
          String? category,
          DateTime? date,
          Value<String?> notes = const Value.absent(),
          bool? isDeleted}) =>
      Expense(
        id: id ?? this.id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        date: date ?? this.date,
        notes: notes.present ? notes.value : this.notes,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, amount, category, date, notes, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.title == this.title &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.date == this.date &&
          other.notes == this.notes &&
          other.isDeleted == this.isDeleted);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<int> id;
  final Value<String> title;
  final Value<double> amount;
  final Value<String> category;
  final Value<DateTime> date;
  final Value<String?> notes;
  final Value<bool> isDeleted;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  ExpensesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required double amount,
    this.category = const Value.absent(),
    required DateTime date,
    this.notes = const Value.absent(),
    this.isDeleted = const Value.absent(),
  })  : title = Value(title),
        amount = Value(amount),
        date = Value(date);
  static Insertable<Expense> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<double>? amount,
    Expression<String>? category,
    Expression<DateTime>? date,
    Expression<String>? notes,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  ExpensesCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<double>? amount,
      Value<String>? category,
      Value<DateTime>? date,
      Value<String?>? notes,
      Value<bool>? isDeleted}) {
    return ExpensesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $DayClosingsTable extends DayClosings
    with TableInfo<$DayClosingsTable, DayClosing> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayClosingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _openingCashMeta =
      const VerificationMeta('openingCash');
  @override
  late final GeneratedColumn<double> openingCash = GeneratedColumn<double>(
      'opening_cash', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _cashSalesMeta =
      const VerificationMeta('cashSales');
  @override
  late final GeneratedColumn<double> cashSales = GeneratedColumn<double>(
      'cash_sales', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _returnsAmountMeta =
      const VerificationMeta('returnsAmount');
  @override
  late final GeneratedColumn<double> returnsAmount = GeneratedColumn<double>(
      'returns_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _cashExpensesMeta =
      const VerificationMeta('cashExpenses');
  @override
  late final GeneratedColumn<double> cashExpenses = GeneratedColumn<double>(
      'cash_expenses', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _expectedCashMeta =
      const VerificationMeta('expectedCash');
  @override
  late final GeneratedColumn<double> expectedCash = GeneratedColumn<double>(
      'expected_cash', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _countedCashMeta =
      const VerificationMeta('countedCash');
  @override
  late final GeneratedColumn<double> countedCash = GeneratedColumn<double>(
      'counted_cash', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _differenceMeta =
      const VerificationMeta('difference');
  @override
  late final GeneratedColumn<double> difference = GeneratedColumn<double>(
      'difference', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _closedAtMeta =
      const VerificationMeta('closedAt');
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
      'closed_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        date,
        openingCash,
        cashSales,
        returnsAmount,
        cashExpenses,
        expectedCash,
        countedCash,
        difference,
        notes,
        closedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_closings';
  @override
  VerificationContext validateIntegrity(Insertable<DayClosing> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('opening_cash')) {
      context.handle(
          _openingCashMeta,
          openingCash.isAcceptableOrUnknown(
              data['opening_cash']!, _openingCashMeta));
    }
    if (data.containsKey('cash_sales')) {
      context.handle(_cashSalesMeta,
          cashSales.isAcceptableOrUnknown(data['cash_sales']!, _cashSalesMeta));
    }
    if (data.containsKey('returns_amount')) {
      context.handle(
          _returnsAmountMeta,
          returnsAmount.isAcceptableOrUnknown(
              data['returns_amount']!, _returnsAmountMeta));
    }
    if (data.containsKey('cash_expenses')) {
      context.handle(
          _cashExpensesMeta,
          cashExpenses.isAcceptableOrUnknown(
              data['cash_expenses']!, _cashExpensesMeta));
    }
    if (data.containsKey('expected_cash')) {
      context.handle(
          _expectedCashMeta,
          expectedCash.isAcceptableOrUnknown(
              data['expected_cash']!, _expectedCashMeta));
    }
    if (data.containsKey('counted_cash')) {
      context.handle(
          _countedCashMeta,
          countedCash.isAcceptableOrUnknown(
              data['counted_cash']!, _countedCashMeta));
    }
    if (data.containsKey('difference')) {
      context.handle(
          _differenceMeta,
          difference.isAcceptableOrUnknown(
              data['difference']!, _differenceMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('closed_at')) {
      context.handle(_closedAtMeta,
          closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayClosing map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayClosing(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      openingCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}opening_cash'])!,
      cashSales: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cash_sales'])!,
      returnsAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}returns_amount'])!,
      cashExpenses: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cash_expenses'])!,
      expectedCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}expected_cash'])!,
      countedCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}counted_cash'])!,
      difference: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}difference'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      closedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}closed_at'])!,
    );
  }

  @override
  $DayClosingsTable createAlias(String alias) {
    return $DayClosingsTable(attachedDatabase, alias);
  }
}

class DayClosing extends DataClass implements Insertable<DayClosing> {
  final int id;
  final DateTime date;
  final double openingCash;
  final double cashSales;
  final double returnsAmount;
  final double cashExpenses;
  final double expectedCash;
  final double countedCash;
  final double difference;
  final String? notes;
  final DateTime closedAt;
  const DayClosing(
      {required this.id,
      required this.date,
      required this.openingCash,
      required this.cashSales,
      required this.returnsAmount,
      required this.cashExpenses,
      required this.expectedCash,
      required this.countedCash,
      required this.difference,
      this.notes,
      required this.closedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['opening_cash'] = Variable<double>(openingCash);
    map['cash_sales'] = Variable<double>(cashSales);
    map['returns_amount'] = Variable<double>(returnsAmount);
    map['cash_expenses'] = Variable<double>(cashExpenses);
    map['expected_cash'] = Variable<double>(expectedCash);
    map['counted_cash'] = Variable<double>(countedCash);
    map['difference'] = Variable<double>(difference);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['closed_at'] = Variable<DateTime>(closedAt);
    return map;
  }

  DayClosingsCompanion toCompanion(bool nullToAbsent) {
    return DayClosingsCompanion(
      id: Value(id),
      date: Value(date),
      openingCash: Value(openingCash),
      cashSales: Value(cashSales),
      returnsAmount: Value(returnsAmount),
      cashExpenses: Value(cashExpenses),
      expectedCash: Value(expectedCash),
      countedCash: Value(countedCash),
      difference: Value(difference),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      closedAt: Value(closedAt),
    );
  }

  factory DayClosing.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayClosing(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      openingCash: serializer.fromJson<double>(json['openingCash']),
      cashSales: serializer.fromJson<double>(json['cashSales']),
      returnsAmount: serializer.fromJson<double>(json['returnsAmount']),
      cashExpenses: serializer.fromJson<double>(json['cashExpenses']),
      expectedCash: serializer.fromJson<double>(json['expectedCash']),
      countedCash: serializer.fromJson<double>(json['countedCash']),
      difference: serializer.fromJson<double>(json['difference']),
      notes: serializer.fromJson<String?>(json['notes']),
      closedAt: serializer.fromJson<DateTime>(json['closedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'openingCash': serializer.toJson<double>(openingCash),
      'cashSales': serializer.toJson<double>(cashSales),
      'returnsAmount': serializer.toJson<double>(returnsAmount),
      'cashExpenses': serializer.toJson<double>(cashExpenses),
      'expectedCash': serializer.toJson<double>(expectedCash),
      'countedCash': serializer.toJson<double>(countedCash),
      'difference': serializer.toJson<double>(difference),
      'notes': serializer.toJson<String?>(notes),
      'closedAt': serializer.toJson<DateTime>(closedAt),
    };
  }

  DayClosing copyWith(
          {int? id,
          DateTime? date,
          double? openingCash,
          double? cashSales,
          double? returnsAmount,
          double? cashExpenses,
          double? expectedCash,
          double? countedCash,
          double? difference,
          Value<String?> notes = const Value.absent(),
          DateTime? closedAt}) =>
      DayClosing(
        id: id ?? this.id,
        date: date ?? this.date,
        openingCash: openingCash ?? this.openingCash,
        cashSales: cashSales ?? this.cashSales,
        returnsAmount: returnsAmount ?? this.returnsAmount,
        cashExpenses: cashExpenses ?? this.cashExpenses,
        expectedCash: expectedCash ?? this.expectedCash,
        countedCash: countedCash ?? this.countedCash,
        difference: difference ?? this.difference,
        notes: notes.present ? notes.value : this.notes,
        closedAt: closedAt ?? this.closedAt,
      );
  DayClosing copyWithCompanion(DayClosingsCompanion data) {
    return DayClosing(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      openingCash:
          data.openingCash.present ? data.openingCash.value : this.openingCash,
      cashSales: data.cashSales.present ? data.cashSales.value : this.cashSales,
      returnsAmount: data.returnsAmount.present
          ? data.returnsAmount.value
          : this.returnsAmount,
      cashExpenses: data.cashExpenses.present
          ? data.cashExpenses.value
          : this.cashExpenses,
      expectedCash: data.expectedCash.present
          ? data.expectedCash.value
          : this.expectedCash,
      countedCash:
          data.countedCash.present ? data.countedCash.value : this.countedCash,
      difference:
          data.difference.present ? data.difference.value : this.difference,
      notes: data.notes.present ? data.notes.value : this.notes,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayClosing(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('openingCash: $openingCash, ')
          ..write('cashSales: $cashSales, ')
          ..write('returnsAmount: $returnsAmount, ')
          ..write('cashExpenses: $cashExpenses, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('countedCash: $countedCash, ')
          ..write('difference: $difference, ')
          ..write('notes: $notes, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      date,
      openingCash,
      cashSales,
      returnsAmount,
      cashExpenses,
      expectedCash,
      countedCash,
      difference,
      notes,
      closedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayClosing &&
          other.id == this.id &&
          other.date == this.date &&
          other.openingCash == this.openingCash &&
          other.cashSales == this.cashSales &&
          other.returnsAmount == this.returnsAmount &&
          other.cashExpenses == this.cashExpenses &&
          other.expectedCash == this.expectedCash &&
          other.countedCash == this.countedCash &&
          other.difference == this.difference &&
          other.notes == this.notes &&
          other.closedAt == this.closedAt);
}

class DayClosingsCompanion extends UpdateCompanion<DayClosing> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<double> openingCash;
  final Value<double> cashSales;
  final Value<double> returnsAmount;
  final Value<double> cashExpenses;
  final Value<double> expectedCash;
  final Value<double> countedCash;
  final Value<double> difference;
  final Value<String?> notes;
  final Value<DateTime> closedAt;
  const DayClosingsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.openingCash = const Value.absent(),
    this.cashSales = const Value.absent(),
    this.returnsAmount = const Value.absent(),
    this.cashExpenses = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.countedCash = const Value.absent(),
    this.difference = const Value.absent(),
    this.notes = const Value.absent(),
    this.closedAt = const Value.absent(),
  });
  DayClosingsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.openingCash = const Value.absent(),
    this.cashSales = const Value.absent(),
    this.returnsAmount = const Value.absent(),
    this.cashExpenses = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.countedCash = const Value.absent(),
    this.difference = const Value.absent(),
    this.notes = const Value.absent(),
    this.closedAt = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DayClosing> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<double>? openingCash,
    Expression<double>? cashSales,
    Expression<double>? returnsAmount,
    Expression<double>? cashExpenses,
    Expression<double>? expectedCash,
    Expression<double>? countedCash,
    Expression<double>? difference,
    Expression<String>? notes,
    Expression<DateTime>? closedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (openingCash != null) 'opening_cash': openingCash,
      if (cashSales != null) 'cash_sales': cashSales,
      if (returnsAmount != null) 'returns_amount': returnsAmount,
      if (cashExpenses != null) 'cash_expenses': cashExpenses,
      if (expectedCash != null) 'expected_cash': expectedCash,
      if (countedCash != null) 'counted_cash': countedCash,
      if (difference != null) 'difference': difference,
      if (notes != null) 'notes': notes,
      if (closedAt != null) 'closed_at': closedAt,
    });
  }

  DayClosingsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<double>? openingCash,
      Value<double>? cashSales,
      Value<double>? returnsAmount,
      Value<double>? cashExpenses,
      Value<double>? expectedCash,
      Value<double>? countedCash,
      Value<double>? difference,
      Value<String?>? notes,
      Value<DateTime>? closedAt}) {
    return DayClosingsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      openingCash: openingCash ?? this.openingCash,
      cashSales: cashSales ?? this.cashSales,
      returnsAmount: returnsAmount ?? this.returnsAmount,
      cashExpenses: cashExpenses ?? this.cashExpenses,
      expectedCash: expectedCash ?? this.expectedCash,
      countedCash: countedCash ?? this.countedCash,
      difference: difference ?? this.difference,
      notes: notes ?? this.notes,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (openingCash.present) {
      map['opening_cash'] = Variable<double>(openingCash.value);
    }
    if (cashSales.present) {
      map['cash_sales'] = Variable<double>(cashSales.value);
    }
    if (returnsAmount.present) {
      map['returns_amount'] = Variable<double>(returnsAmount.value);
    }
    if (cashExpenses.present) {
      map['cash_expenses'] = Variable<double>(cashExpenses.value);
    }
    if (expectedCash.present) {
      map['expected_cash'] = Variable<double>(expectedCash.value);
    }
    if (countedCash.present) {
      map['counted_cash'] = Variable<double>(countedCash.value);
    }
    if (difference.present) {
      map['difference'] = Variable<double>(difference.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayClosingsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('openingCash: $openingCash, ')
          ..write('cashSales: $cashSales, ')
          ..write('returnsAmount: $returnsAmount, ')
          ..write('cashExpenses: $cashExpenses, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('countedCash: $countedCash, ')
          ..write('difference: $difference, ')
          ..write('notes: $notes, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }
}

class $StoreSettingsTable extends StoreSettings
    with TableInfo<$StoreSettingsTable, StoreSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoreSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'store_settings';
  @override
  VerificationContext validateIntegrity(Insertable<StoreSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  StoreSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoreSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $StoreSettingsTable createAlias(String alias) {
    return $StoreSettingsTable(attachedDatabase, alias);
  }
}

class StoreSetting extends DataClass implements Insertable<StoreSetting> {
  final String key;
  final String value;
  const StoreSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  StoreSettingsCompanion toCompanion(bool nullToAbsent) {
    return StoreSettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory StoreSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  StoreSetting copyWith({String? key, String? value}) => StoreSetting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  StoreSetting copyWithCompanion(StoreSettingsCompanion data) {
    return StoreSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoreSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class StoreSettingsCompanion extends UpdateCompanion<StoreSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const StoreSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoreSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<StoreSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoreSettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return StoreSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoreSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductVariantsTable extends ProductVariants
    with TableInfo<$ProductVariantsTable, ProductVariant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductVariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES products (id) ON DELETE CASCADE'));
  static const VerificationMeta _variantNameMeta =
      const VerificationMeta('variantName');
  @override
  late final GeneratedColumn<String> variantName = GeneratedColumn<String>(
      'variant_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Standard'));
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _costPriceMeta =
      const VerificationMeta('costPrice');
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
      'cost_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        productId,
        variantName,
        price,
        costPrice,
        sku,
        isDefault,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_variants';
  @override
  VerificationContext validateIntegrity(Insertable<ProductVariant> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('variant_name')) {
      context.handle(
          _variantNameMeta,
          variantName.isAcceptableOrUnknown(
              data['variant_name']!, _variantNameMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('cost_price')) {
      context.handle(_costPriceMeta,
          costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta));
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductVariant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductVariant(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id'])!,
      variantName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}variant_name'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      costPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_price'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku']),
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProductVariantsTable createAlias(String alias) {
    return $ProductVariantsTable(attachedDatabase, alias);
  }
}

class ProductVariant extends DataClass implements Insertable<ProductVariant> {
  final int id;
  final int productId;
  final String variantName;
  final double price;
  final double costPrice;
  final String? sku;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProductVariant(
      {required this.id,
      required this.productId,
      required this.variantName,
      required this.price,
      required this.costPrice,
      this.sku,
      required this.isDefault,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['variant_name'] = Variable<String>(variantName);
    map['price'] = Variable<double>(price);
    map['cost_price'] = Variable<double>(costPrice);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductVariantsCompanion toCompanion(bool nullToAbsent) {
    return ProductVariantsCompanion(
      id: Value(id),
      productId: Value(productId),
      variantName: Value(variantName),
      price: Value(price),
      costPrice: Value(costPrice),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductVariant(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      variantName: serializer.fromJson<String>(json['variantName']),
      price: serializer.fromJson<double>(json['price']),
      costPrice: serializer.fromJson<double>(json['costPrice']),
      sku: serializer.fromJson<String?>(json['sku']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'variantName': serializer.toJson<String>(variantName),
      'price': serializer.toJson<double>(price),
      'costPrice': serializer.toJson<double>(costPrice),
      'sku': serializer.toJson<String?>(sku),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductVariant copyWith(
          {int? id,
          int? productId,
          String? variantName,
          double? price,
          double? costPrice,
          Value<String?> sku = const Value.absent(),
          bool? isDefault,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ProductVariant(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        variantName: variantName ?? this.variantName,
        price: price ?? this.price,
        costPrice: costPrice ?? this.costPrice,
        sku: sku.present ? sku.value : this.sku,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ProductVariant copyWithCompanion(ProductVariantsCompanion data) {
    return ProductVariant(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      variantName:
          data.variantName.present ? data.variantName.value : this.variantName,
      price: data.price.present ? data.price.value : this.price,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      sku: data.sku.present ? data.sku.value : this.sku,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductVariant(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('variantName: $variantName, ')
          ..write('price: $price, ')
          ..write('costPrice: $costPrice, ')
          ..write('sku: $sku, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productId, variantName, price, costPrice,
      sku, isDefault, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductVariant &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.variantName == this.variantName &&
          other.price == this.price &&
          other.costPrice == this.costPrice &&
          other.sku == this.sku &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductVariantsCompanion extends UpdateCompanion<ProductVariant> {
  final Value<int> id;
  final Value<int> productId;
  final Value<String> variantName;
  final Value<double> price;
  final Value<double> costPrice;
  final Value<String?> sku;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProductVariantsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.variantName = const Value.absent(),
    this.price = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.sku = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProductVariantsCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    this.variantName = const Value.absent(),
    required double price,
    this.costPrice = const Value.absent(),
    this.sku = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : productId = Value(productId),
        price = Value(price);
  static Insertable<ProductVariant> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<String>? variantName,
    Expression<double>? price,
    Expression<double>? costPrice,
    Expression<String>? sku,
    Expression<bool>? isDefault,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (variantName != null) 'variant_name': variantName,
      if (price != null) 'price': price,
      if (costPrice != null) 'cost_price': costPrice,
      if (sku != null) 'sku': sku,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProductVariantsCompanion copyWith(
      {Value<int>? id,
      Value<int>? productId,
      Value<String>? variantName,
      Value<double>? price,
      Value<double>? costPrice,
      Value<String?>? sku,
      Value<bool>? isDefault,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return ProductVariantsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      variantName: variantName ?? this.variantName,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      sku: sku ?? this.sku,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (variantName.present) {
      map['variant_name'] = Variable<String>(variantName.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductVariantsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('variantName: $variantName, ')
          ..write('price: $price, ')
          ..write('costPrice: $costPrice, ')
          ..write('sku: $sku, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ProductBarcodesTable extends ProductBarcodes
    with TableInfo<$ProductBarcodesTable, ProductBarcode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductBarcodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _variantIdMeta =
      const VerificationMeta('variantId');
  @override
  late final GeneratedColumn<int> variantId = GeneratedColumn<int>(
      'variant_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES product_variants (id) ON DELETE CASCADE'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES products (id) ON DELETE CASCADE'));
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _isPrimaryMeta =
      const VerificationMeta('isPrimary');
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
      'is_primary', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_primary" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, variantId, productId, barcode, isPrimary, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_barcodes';
  @override
  VerificationContext validateIntegrity(Insertable<ProductBarcode> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('variant_id')) {
      context.handle(_variantIdMeta,
          variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('is_primary')) {
      context.handle(_isPrimaryMeta,
          isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductBarcode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductBarcode(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      variantId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}variant_id']),
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode'])!,
      isPrimary: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_primary'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ProductBarcodesTable createAlias(String alias) {
    return $ProductBarcodesTable(attachedDatabase, alias);
  }
}

class ProductBarcode extends DataClass implements Insertable<ProductBarcode> {
  final int id;
  final int? variantId;
  final int productId;
  final String barcode;
  final bool isPrimary;
  final DateTime createdAt;
  const ProductBarcode(
      {required this.id,
      this.variantId,
      required this.productId,
      required this.barcode,
      required this.isPrimary,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || variantId != null) {
      map['variant_id'] = Variable<int>(variantId);
    }
    map['product_id'] = Variable<int>(productId);
    map['barcode'] = Variable<String>(barcode);
    map['is_primary'] = Variable<bool>(isPrimary);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProductBarcodesCompanion toCompanion(bool nullToAbsent) {
    return ProductBarcodesCompanion(
      id: Value(id),
      variantId: variantId == null && nullToAbsent
          ? const Value.absent()
          : Value(variantId),
      productId: Value(productId),
      barcode: Value(barcode),
      isPrimary: Value(isPrimary),
      createdAt: Value(createdAt),
    );
  }

  factory ProductBarcode.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductBarcode(
      id: serializer.fromJson<int>(json['id']),
      variantId: serializer.fromJson<int?>(json['variantId']),
      productId: serializer.fromJson<int>(json['productId']),
      barcode: serializer.fromJson<String>(json['barcode']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'variantId': serializer.toJson<int?>(variantId),
      'productId': serializer.toJson<int>(productId),
      'barcode': serializer.toJson<String>(barcode),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProductBarcode copyWith(
          {int? id,
          Value<int?> variantId = const Value.absent(),
          int? productId,
          String? barcode,
          bool? isPrimary,
          DateTime? createdAt}) =>
      ProductBarcode(
        id: id ?? this.id,
        variantId: variantId.present ? variantId.value : this.variantId,
        productId: productId ?? this.productId,
        barcode: barcode ?? this.barcode,
        isPrimary: isPrimary ?? this.isPrimary,
        createdAt: createdAt ?? this.createdAt,
      );
  ProductBarcode copyWithCompanion(ProductBarcodesCompanion data) {
    return ProductBarcode(
      id: data.id.present ? data.id.value : this.id,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      productId: data.productId.present ? data.productId.value : this.productId,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductBarcode(')
          ..write('id: $id, ')
          ..write('variantId: $variantId, ')
          ..write('productId: $productId, ')
          ..write('barcode: $barcode, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, variantId, productId, barcode, isPrimary, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductBarcode &&
          other.id == this.id &&
          other.variantId == this.variantId &&
          other.productId == this.productId &&
          other.barcode == this.barcode &&
          other.isPrimary == this.isPrimary &&
          other.createdAt == this.createdAt);
}

class ProductBarcodesCompanion extends UpdateCompanion<ProductBarcode> {
  final Value<int> id;
  final Value<int?> variantId;
  final Value<int> productId;
  final Value<String> barcode;
  final Value<bool> isPrimary;
  final Value<DateTime> createdAt;
  const ProductBarcodesCompanion({
    this.id = const Value.absent(),
    this.variantId = const Value.absent(),
    this.productId = const Value.absent(),
    this.barcode = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProductBarcodesCompanion.insert({
    this.id = const Value.absent(),
    this.variantId = const Value.absent(),
    required int productId,
    required String barcode,
    this.isPrimary = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : productId = Value(productId),
        barcode = Value(barcode);
  static Insertable<ProductBarcode> custom({
    Expression<int>? id,
    Expression<int>? variantId,
    Expression<int>? productId,
    Expression<String>? barcode,
    Expression<bool>? isPrimary,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (variantId != null) 'variant_id': variantId,
      if (productId != null) 'product_id': productId,
      if (barcode != null) 'barcode': barcode,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProductBarcodesCompanion copyWith(
      {Value<int>? id,
      Value<int?>? variantId,
      Value<int>? productId,
      Value<String>? barcode,
      Value<bool>? isPrimary,
      Value<DateTime>? createdAt}) {
    return ProductBarcodesCompanion(
      id: id ?? this.id,
      variantId: variantId ?? this.variantId,
      productId: productId ?? this.productId,
      barcode: barcode ?? this.barcode,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<int>(variantId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductBarcodesCompanion(')
          ..write('id: $id, ')
          ..write('variantId: $variantId, ')
          ..write('productId: $productId, ')
          ..write('barcode: $barcode, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $UnmatchedScansTable extends UnmatchedScans
    with TableInfo<$UnmatchedScansTable, UnmatchedScan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnmatchedScansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scanCountMeta =
      const VerificationMeta('scanCount');
  @override
  late final GeneratedColumn<int> scanCount = GeneratedColumn<int>(
      'scan_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _lastScannedAtMeta =
      const VerificationMeta('lastScannedAt');
  @override
  late final GeneratedColumn<DateTime> lastScannedAt =
      GeneratedColumn<DateTime>('last_scanned_at', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, barcode, scanCount, lastScannedAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unmatched_scans';
  @override
  VerificationContext validateIntegrity(Insertable<UnmatchedScan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('scan_count')) {
      context.handle(_scanCountMeta,
          scanCount.isAcceptableOrUnknown(data['scan_count']!, _scanCountMeta));
    }
    if (data.containsKey('last_scanned_at')) {
      context.handle(
          _lastScannedAtMeta,
          lastScannedAt.isAcceptableOrUnknown(
              data['last_scanned_at']!, _lastScannedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnmatchedScan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnmatchedScan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode'])!,
      scanCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}scan_count'])!,
      lastScannedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_scanned_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $UnmatchedScansTable createAlias(String alias) {
    return $UnmatchedScansTable(attachedDatabase, alias);
  }
}

class UnmatchedScan extends DataClass implements Insertable<UnmatchedScan> {
  final int id;
  final String barcode;
  final int scanCount;
  final DateTime lastScannedAt;
  final DateTime createdAt;
  const UnmatchedScan(
      {required this.id,
      required this.barcode,
      required this.scanCount,
      required this.lastScannedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['barcode'] = Variable<String>(barcode);
    map['scan_count'] = Variable<int>(scanCount);
    map['last_scanned_at'] = Variable<DateTime>(lastScannedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UnmatchedScansCompanion toCompanion(bool nullToAbsent) {
    return UnmatchedScansCompanion(
      id: Value(id),
      barcode: Value(barcode),
      scanCount: Value(scanCount),
      lastScannedAt: Value(lastScannedAt),
      createdAt: Value(createdAt),
    );
  }

  factory UnmatchedScan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnmatchedScan(
      id: serializer.fromJson<int>(json['id']),
      barcode: serializer.fromJson<String>(json['barcode']),
      scanCount: serializer.fromJson<int>(json['scanCount']),
      lastScannedAt: serializer.fromJson<DateTime>(json['lastScannedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'barcode': serializer.toJson<String>(barcode),
      'scanCount': serializer.toJson<int>(scanCount),
      'lastScannedAt': serializer.toJson<DateTime>(lastScannedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UnmatchedScan copyWith(
          {int? id,
          String? barcode,
          int? scanCount,
          DateTime? lastScannedAt,
          DateTime? createdAt}) =>
      UnmatchedScan(
        id: id ?? this.id,
        barcode: barcode ?? this.barcode,
        scanCount: scanCount ?? this.scanCount,
        lastScannedAt: lastScannedAt ?? this.lastScannedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  UnmatchedScan copyWithCompanion(UnmatchedScansCompanion data) {
    return UnmatchedScan(
      id: data.id.present ? data.id.value : this.id,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      scanCount: data.scanCount.present ? data.scanCount.value : this.scanCount,
      lastScannedAt: data.lastScannedAt.present
          ? data.lastScannedAt.value
          : this.lastScannedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnmatchedScan(')
          ..write('id: $id, ')
          ..write('barcode: $barcode, ')
          ..write('scanCount: $scanCount, ')
          ..write('lastScannedAt: $lastScannedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, barcode, scanCount, lastScannedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnmatchedScan &&
          other.id == this.id &&
          other.barcode == this.barcode &&
          other.scanCount == this.scanCount &&
          other.lastScannedAt == this.lastScannedAt &&
          other.createdAt == this.createdAt);
}

class UnmatchedScansCompanion extends UpdateCompanion<UnmatchedScan> {
  final Value<int> id;
  final Value<String> barcode;
  final Value<int> scanCount;
  final Value<DateTime> lastScannedAt;
  final Value<DateTime> createdAt;
  const UnmatchedScansCompanion({
    this.id = const Value.absent(),
    this.barcode = const Value.absent(),
    this.scanCount = const Value.absent(),
    this.lastScannedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UnmatchedScansCompanion.insert({
    this.id = const Value.absent(),
    required String barcode,
    this.scanCount = const Value.absent(),
    this.lastScannedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : barcode = Value(barcode);
  static Insertable<UnmatchedScan> custom({
    Expression<int>? id,
    Expression<String>? barcode,
    Expression<int>? scanCount,
    Expression<DateTime>? lastScannedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (barcode != null) 'barcode': barcode,
      if (scanCount != null) 'scan_count': scanCount,
      if (lastScannedAt != null) 'last_scanned_at': lastScannedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UnmatchedScansCompanion copyWith(
      {Value<int>? id,
      Value<String>? barcode,
      Value<int>? scanCount,
      Value<DateTime>? lastScannedAt,
      Value<DateTime>? createdAt}) {
    return UnmatchedScansCompanion(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      scanCount: scanCount ?? this.scanCount,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (scanCount.present) {
      map['scan_count'] = Variable<int>(scanCount.value);
    }
    if (lastScannedAt.present) {
      map['last_scanned_at'] = Variable<DateTime>(lastScannedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnmatchedScansCompanion(')
          ..write('id: $id, ')
          ..write('barcode: $barcode, ')
          ..write('scanCount: $scanCount, ')
          ..write('lastScannedAt: $lastScannedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $UnitsTable units = $UnitsTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $BillsTable bills = $BillsTable(this);
  late final $BillItemsTable billItems = $BillItemsTable(this);
  late final $BillEditsTable billEdits = $BillEditsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $DayClosingsTable dayClosings = $DayClosingsTable(this);
  late final $StoreSettingsTable storeSettings = $StoreSettingsTable(this);
  late final $ProductVariantsTable productVariants =
      $ProductVariantsTable(this);
  late final $ProductBarcodesTable productBarcodes =
      $ProductBarcodesTable(this);
  late final $UnmatchedScansTable unmatchedScans = $UnmatchedScansTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        categories,
        products,
        units,
        customers,
        bills,
        billItems,
        billEdits,
        expenses,
        dayClosings,
        storeSettings,
        productVariants,
        productBarcodes,
        unmatchedScans
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('bills',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('bill_items', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('bills',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('bill_edits', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('products',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('product_variants', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('product_variants',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('product_barcodes', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('products',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('product_barcodes', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> colorHex,
  Value<String?> iconName,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> colorHex,
  Value<String?> iconName,
});

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CategoriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CategoriesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> colorHex = const Value.absent(),
            Value<String?> iconName = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            colorHex: colorHex,
            iconName: iconName,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> colorHex = const Value.absent(),
            Value<String?> iconName = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            colorHex: colorHex,
            iconName: iconName,
          ),
        ));
}

class $$CategoriesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get colorHex => $state.composableBuilder(
      column: $state.table.colorHex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get iconName => $state.composableBuilder(
      column: $state.table.iconName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter productsRefs(
      ComposableFilter Function($$ProductsTableFilterComposer f) f) {
    final $$ProductsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.products,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder, parentComposers) =>
            $$ProductsTableFilterComposer(ComposerState(
                $state.db, $state.db.products, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get colorHex => $state.composableBuilder(
      column: $state.table.colorHex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get iconName => $state.composableBuilder(
      column: $state.table.iconName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  required String name,
  required double price,
  Value<double> gstRate,
  Value<String> unit,
  Value<int?> categoryId,
  Value<String?> barcode,
  Value<String?> imagePath,
  Value<bool> isFavorite,
  Value<bool> isDeleted,
  Value<DateTime?> deletedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<double> price,
  Value<double> gstRate,
  Value<String> unit,
  Value<int?> categoryId,
  Value<String?> barcode,
  Value<String?> imagePath,
  Value<bool> isFavorite,
  Value<bool> isDeleted,
  Value<DateTime?> deletedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ProductsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ProductsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<double> gstRate = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            name: name,
            price: price,
            gstRate: gstRate,
            unit: unit,
            categoryId: categoryId,
            barcode: barcode,
            imagePath: imagePath,
            isFavorite: isFavorite,
            isDeleted: isDeleted,
            deletedAt: deletedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required double price,
            Value<double> gstRate = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            name: name,
            price: price,
            gstRate: gstRate,
            unit: unit,
            categoryId: categoryId,
            barcode: barcode,
            imagePath: imagePath,
            isFavorite: isFavorite,
            isDeleted: isDeleted,
            deletedAt: deletedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$ProductsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get price => $state.composableBuilder(
      column: $state.table.price,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get gstRate => $state.composableBuilder(
      column: $state.table.gstRate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get barcode => $state.composableBuilder(
      column: $state.table.barcode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get imagePath => $state.composableBuilder(
      column: $state.table.imagePath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableFilterComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter productVariantsRefs(
      ComposableFilter Function($$ProductVariantsTableFilterComposer f) f) {
    final $$ProductVariantsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.productVariants,
            getReferencedColumn: (t) => t.productId,
            builder: (joinBuilder, parentComposers) =>
                $$ProductVariantsTableFilterComposer(ComposerState($state.db,
                    $state.db.productVariants, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter productBarcodesRefs(
      ComposableFilter Function($$ProductBarcodesTableFilterComposer f) f) {
    final $$ProductBarcodesTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.productBarcodes,
            getReferencedColumn: (t) => t.productId,
            builder: (joinBuilder, parentComposers) =>
                $$ProductBarcodesTableFilterComposer(ComposerState($state.db,
                    $state.db.productBarcodes, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get price => $state.composableBuilder(
      column: $state.table.price,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get gstRate => $state.composableBuilder(
      column: $state.table.gstRate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get barcode => $state.composableBuilder(
      column: $state.table.barcode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get imagePath => $state.composableBuilder(
      column: $state.table.imagePath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableOrderingComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$UnitsTableCreateCompanionBuilder = UnitsCompanion Function({
  Value<int> id,
  required String code,
  required String name,
  Value<bool> isDecimalAllowed,
});
typedef $$UnitsTableUpdateCompanionBuilder = UnitsCompanion Function({
  Value<int> id,
  Value<String> code,
  Value<String> name,
  Value<bool> isDecimalAllowed,
});

class $$UnitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UnitsTable,
    Unit,
    $$UnitsTableFilterComposer,
    $$UnitsTableOrderingComposer,
    $$UnitsTableCreateCompanionBuilder,
    $$UnitsTableUpdateCompanionBuilder> {
  $$UnitsTableTableManager(_$AppDatabase db, $UnitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$UnitsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$UnitsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isDecimalAllowed = const Value.absent(),
          }) =>
              UnitsCompanion(
            id: id,
            code: code,
            name: name,
            isDecimalAllowed: isDecimalAllowed,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String code,
            required String name,
            Value<bool> isDecimalAllowed = const Value.absent(),
          }) =>
              UnitsCompanion.insert(
            id: id,
            code: code,
            name: name,
            isDecimalAllowed: isDecimalAllowed,
          ),
        ));
}

class $$UnitsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get code => $state.composableBuilder(
      column: $state.table.code,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDecimalAllowed => $state.composableBuilder(
      column: $state.table.isDecimalAllowed,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$UnitsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get code => $state.composableBuilder(
      column: $state.table.code,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDecimalAllowed => $state.composableBuilder(
      column: $state.table.isDecimalAllowed,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> phone,
  Value<double> balance,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> phone,
  Value<double> balance,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$CustomersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder> {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CustomersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CustomersTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<double> balance = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CustomersCompanion(
            id: id,
            name: name,
            phone: phone,
            balance: balance,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> phone = const Value.absent(),
            Value<double> balance = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CustomersCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            balance: balance,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$CustomersTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get balance => $state.composableBuilder(
      column: $state.table.balance,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter billsRefs(
      ComposableFilter Function($$BillsTableFilterComposer f) f) {
    final $$BillsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.bills,
        getReferencedColumn: (t) => t.customerId,
        builder: (joinBuilder, parentComposers) => $$BillsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.bills, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$CustomersTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get balance => $state.composableBuilder(
      column: $state.table.balance,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$BillsTableCreateCompanionBuilder = BillsCompanion Function({
  Value<int> id,
  required String billNumber,
  required DateTime date,
  Value<int?> customerId,
  Value<String?> customerName,
  Value<String?> customerPhone,
  Value<String> paymentMode,
  Value<double> cashAmount,
  Value<double> digitalAmount,
  Value<double> changeTendered,
  Value<double> subtotal,
  Value<double> itemDiscountTotal,
  Value<double> billDiscountPercent,
  Value<double> billDiscountAmount,
  Value<String> gstType,
  Value<double> cgstTotal,
  Value<double> sgstTotal,
  Value<double> igstTotal,
  Value<double> roundOff,
  Value<double> grandTotal,
  Value<String?> notes,
  Value<bool> isHeld,
  Value<bool> isCreditPaid,
  Value<bool> isEdited,
  Value<bool> isDeleted,
  Value<DateTime?> deletedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$BillsTableUpdateCompanionBuilder = BillsCompanion Function({
  Value<int> id,
  Value<String> billNumber,
  Value<DateTime> date,
  Value<int?> customerId,
  Value<String?> customerName,
  Value<String?> customerPhone,
  Value<String> paymentMode,
  Value<double> cashAmount,
  Value<double> digitalAmount,
  Value<double> changeTendered,
  Value<double> subtotal,
  Value<double> itemDiscountTotal,
  Value<double> billDiscountPercent,
  Value<double> billDiscountAmount,
  Value<String> gstType,
  Value<double> cgstTotal,
  Value<double> sgstTotal,
  Value<double> igstTotal,
  Value<double> roundOff,
  Value<double> grandTotal,
  Value<String?> notes,
  Value<bool> isHeld,
  Value<bool> isCreditPaid,
  Value<bool> isEdited,
  Value<bool> isDeleted,
  Value<DateTime?> deletedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$BillsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BillsTable,
    Bill,
    $$BillsTableFilterComposer,
    $$BillsTableOrderingComposer,
    $$BillsTableCreateCompanionBuilder,
    $$BillsTableUpdateCompanionBuilder> {
  $$BillsTableTableManager(_$AppDatabase db, $BillsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BillsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BillsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> billNumber = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int?> customerId = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<String?> customerPhone = const Value.absent(),
            Value<String> paymentMode = const Value.absent(),
            Value<double> cashAmount = const Value.absent(),
            Value<double> digitalAmount = const Value.absent(),
            Value<double> changeTendered = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> itemDiscountTotal = const Value.absent(),
            Value<double> billDiscountPercent = const Value.absent(),
            Value<double> billDiscountAmount = const Value.absent(),
            Value<String> gstType = const Value.absent(),
            Value<double> cgstTotal = const Value.absent(),
            Value<double> sgstTotal = const Value.absent(),
            Value<double> igstTotal = const Value.absent(),
            Value<double> roundOff = const Value.absent(),
            Value<double> grandTotal = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isHeld = const Value.absent(),
            Value<bool> isCreditPaid = const Value.absent(),
            Value<bool> isEdited = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BillsCompanion(
            id: id,
            billNumber: billNumber,
            date: date,
            customerId: customerId,
            customerName: customerName,
            customerPhone: customerPhone,
            paymentMode: paymentMode,
            cashAmount: cashAmount,
            digitalAmount: digitalAmount,
            changeTendered: changeTendered,
            subtotal: subtotal,
            itemDiscountTotal: itemDiscountTotal,
            billDiscountPercent: billDiscountPercent,
            billDiscountAmount: billDiscountAmount,
            gstType: gstType,
            cgstTotal: cgstTotal,
            sgstTotal: sgstTotal,
            igstTotal: igstTotal,
            roundOff: roundOff,
            grandTotal: grandTotal,
            notes: notes,
            isHeld: isHeld,
            isCreditPaid: isCreditPaid,
            isEdited: isEdited,
            isDeleted: isDeleted,
            deletedAt: deletedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String billNumber,
            required DateTime date,
            Value<int?> customerId = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<String?> customerPhone = const Value.absent(),
            Value<String> paymentMode = const Value.absent(),
            Value<double> cashAmount = const Value.absent(),
            Value<double> digitalAmount = const Value.absent(),
            Value<double> changeTendered = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> itemDiscountTotal = const Value.absent(),
            Value<double> billDiscountPercent = const Value.absent(),
            Value<double> billDiscountAmount = const Value.absent(),
            Value<String> gstType = const Value.absent(),
            Value<double> cgstTotal = const Value.absent(),
            Value<double> sgstTotal = const Value.absent(),
            Value<double> igstTotal = const Value.absent(),
            Value<double> roundOff = const Value.absent(),
            Value<double> grandTotal = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isHeld = const Value.absent(),
            Value<bool> isCreditPaid = const Value.absent(),
            Value<bool> isEdited = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BillsCompanion.insert(
            id: id,
            billNumber: billNumber,
            date: date,
            customerId: customerId,
            customerName: customerName,
            customerPhone: customerPhone,
            paymentMode: paymentMode,
            cashAmount: cashAmount,
            digitalAmount: digitalAmount,
            changeTendered: changeTendered,
            subtotal: subtotal,
            itemDiscountTotal: itemDiscountTotal,
            billDiscountPercent: billDiscountPercent,
            billDiscountAmount: billDiscountAmount,
            gstType: gstType,
            cgstTotal: cgstTotal,
            sgstTotal: sgstTotal,
            igstTotal: igstTotal,
            roundOff: roundOff,
            grandTotal: grandTotal,
            notes: notes,
            isHeld: isHeld,
            isCreditPaid: isCreditPaid,
            isEdited: isEdited,
            isDeleted: isDeleted,
            deletedAt: deletedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$BillsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BillsTable> {
  $$BillsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get billNumber => $state.composableBuilder(
      column: $state.table.billNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customerName => $state.composableBuilder(
      column: $state.table.customerName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customerPhone => $state.composableBuilder(
      column: $state.table.customerPhone,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get paymentMode => $state.composableBuilder(
      column: $state.table.paymentMode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get cashAmount => $state.composableBuilder(
      column: $state.table.cashAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get digitalAmount => $state.composableBuilder(
      column: $state.table.digitalAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get changeTendered => $state.composableBuilder(
      column: $state.table.changeTendered,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get subtotal => $state.composableBuilder(
      column: $state.table.subtotal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get itemDiscountTotal => $state.composableBuilder(
      column: $state.table.itemDiscountTotal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get billDiscountPercent => $state.composableBuilder(
      column: $state.table.billDiscountPercent,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get billDiscountAmount => $state.composableBuilder(
      column: $state.table.billDiscountAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get gstType => $state.composableBuilder(
      column: $state.table.gstType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get cgstTotal => $state.composableBuilder(
      column: $state.table.cgstTotal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get sgstTotal => $state.composableBuilder(
      column: $state.table.sgstTotal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get igstTotal => $state.composableBuilder(
      column: $state.table.igstTotal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get roundOff => $state.composableBuilder(
      column: $state.table.roundOff,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get grandTotal => $state.composableBuilder(
      column: $state.table.grandTotal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isHeld => $state.composableBuilder(
      column: $state.table.isHeld,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isCreditPaid => $state.composableBuilder(
      column: $state.table.isCreditPaid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isEdited => $state.composableBuilder(
      column: $state.table.isEdited,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CustomersTableFilterComposer get customerId {
    final $$CustomersTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $state.db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CustomersTableFilterComposer(ComposerState(
                $state.db, $state.db.customers, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter billItemsRefs(
      ComposableFilter Function($$BillItemsTableFilterComposer f) f) {
    final $$BillItemsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.billItems,
        getReferencedColumn: (t) => t.billId,
        builder: (joinBuilder, parentComposers) =>
            $$BillItemsTableFilterComposer(ComposerState(
                $state.db, $state.db.billItems, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter billEditsRefs(
      ComposableFilter Function($$BillEditsTableFilterComposer f) f) {
    final $$BillEditsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.billEdits,
        getReferencedColumn: (t) => t.billId,
        builder: (joinBuilder, parentComposers) =>
            $$BillEditsTableFilterComposer(ComposerState(
                $state.db, $state.db.billEdits, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$BillsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BillsTable> {
  $$BillsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get billNumber => $state.composableBuilder(
      column: $state.table.billNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customerName => $state.composableBuilder(
      column: $state.table.customerName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customerPhone => $state.composableBuilder(
      column: $state.table.customerPhone,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get paymentMode => $state.composableBuilder(
      column: $state.table.paymentMode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get cashAmount => $state.composableBuilder(
      column: $state.table.cashAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get digitalAmount => $state.composableBuilder(
      column: $state.table.digitalAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get changeTendered => $state.composableBuilder(
      column: $state.table.changeTendered,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get subtotal => $state.composableBuilder(
      column: $state.table.subtotal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get itemDiscountTotal => $state.composableBuilder(
      column: $state.table.itemDiscountTotal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get billDiscountPercent => $state.composableBuilder(
      column: $state.table.billDiscountPercent,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get billDiscountAmount => $state.composableBuilder(
      column: $state.table.billDiscountAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get gstType => $state.composableBuilder(
      column: $state.table.gstType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get cgstTotal => $state.composableBuilder(
      column: $state.table.cgstTotal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get sgstTotal => $state.composableBuilder(
      column: $state.table.sgstTotal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get igstTotal => $state.composableBuilder(
      column: $state.table.igstTotal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get roundOff => $state.composableBuilder(
      column: $state.table.roundOff,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get grandTotal => $state.composableBuilder(
      column: $state.table.grandTotal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isHeld => $state.composableBuilder(
      column: $state.table.isHeld,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isCreditPaid => $state.composableBuilder(
      column: $state.table.isCreditPaid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isEdited => $state.composableBuilder(
      column: $state.table.isEdited,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CustomersTableOrderingComposer get customerId {
    final $$CustomersTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $state.db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CustomersTableOrderingComposer(ComposerState(
                $state.db, $state.db.customers, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$BillItemsTableCreateCompanionBuilder = BillItemsCompanion Function({
  Value<int> id,
  required int billId,
  Value<int?> productId,
  required String productName,
  Value<String> unit,
  Value<double> quantity,
  required double unitPrice,
  Value<double> discountAmount,
  Value<double> gstRate,
  Value<double> gstAmount,
  Value<double> taxableValue,
  Value<double> cgstAmount,
  Value<double> sgstAmount,
  Value<double> igstAmount,
  required double totalAmount,
});
typedef $$BillItemsTableUpdateCompanionBuilder = BillItemsCompanion Function({
  Value<int> id,
  Value<int> billId,
  Value<int?> productId,
  Value<String> productName,
  Value<String> unit,
  Value<double> quantity,
  Value<double> unitPrice,
  Value<double> discountAmount,
  Value<double> gstRate,
  Value<double> gstAmount,
  Value<double> taxableValue,
  Value<double> cgstAmount,
  Value<double> sgstAmount,
  Value<double> igstAmount,
  Value<double> totalAmount,
});

class $$BillItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BillItemsTable,
    BillItem,
    $$BillItemsTableFilterComposer,
    $$BillItemsTableOrderingComposer,
    $$BillItemsTableCreateCompanionBuilder,
    $$BillItemsTableUpdateCompanionBuilder> {
  $$BillItemsTableTableManager(_$AppDatabase db, $BillItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BillItemsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BillItemsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> billId = const Value.absent(),
            Value<int?> productId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double> unitPrice = const Value.absent(),
            Value<double> discountAmount = const Value.absent(),
            Value<double> gstRate = const Value.absent(),
            Value<double> gstAmount = const Value.absent(),
            Value<double> taxableValue = const Value.absent(),
            Value<double> cgstAmount = const Value.absent(),
            Value<double> sgstAmount = const Value.absent(),
            Value<double> igstAmount = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
          }) =>
              BillItemsCompanion(
            id: id,
            billId: billId,
            productId: productId,
            productName: productName,
            unit: unit,
            quantity: quantity,
            unitPrice: unitPrice,
            discountAmount: discountAmount,
            gstRate: gstRate,
            gstAmount: gstAmount,
            taxableValue: taxableValue,
            cgstAmount: cgstAmount,
            sgstAmount: sgstAmount,
            igstAmount: igstAmount,
            totalAmount: totalAmount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int billId,
            Value<int?> productId = const Value.absent(),
            required String productName,
            Value<String> unit = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            required double unitPrice,
            Value<double> discountAmount = const Value.absent(),
            Value<double> gstRate = const Value.absent(),
            Value<double> gstAmount = const Value.absent(),
            Value<double> taxableValue = const Value.absent(),
            Value<double> cgstAmount = const Value.absent(),
            Value<double> sgstAmount = const Value.absent(),
            Value<double> igstAmount = const Value.absent(),
            required double totalAmount,
          }) =>
              BillItemsCompanion.insert(
            id: id,
            billId: billId,
            productId: productId,
            productName: productName,
            unit: unit,
            quantity: quantity,
            unitPrice: unitPrice,
            discountAmount: discountAmount,
            gstRate: gstRate,
            gstAmount: gstAmount,
            taxableValue: taxableValue,
            cgstAmount: cgstAmount,
            sgstAmount: sgstAmount,
            igstAmount: igstAmount,
            totalAmount: totalAmount,
          ),
        ));
}

class $$BillItemsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BillItemsTable> {
  $$BillItemsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get productId => $state.composableBuilder(
      column: $state.table.productId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get productName => $state.composableBuilder(
      column: $state.table.productName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get unitPrice => $state.composableBuilder(
      column: $state.table.unitPrice,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get discountAmount => $state.composableBuilder(
      column: $state.table.discountAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get gstRate => $state.composableBuilder(
      column: $state.table.gstRate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get gstAmount => $state.composableBuilder(
      column: $state.table.gstAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get taxableValue => $state.composableBuilder(
      column: $state.table.taxableValue,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get cgstAmount => $state.composableBuilder(
      column: $state.table.cgstAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get sgstAmount => $state.composableBuilder(
      column: $state.table.sgstAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get igstAmount => $state.composableBuilder(
      column: $state.table.igstAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get totalAmount => $state.composableBuilder(
      column: $state.table.totalAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$BillsTableFilterComposer get billId {
    final $$BillsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.billId,
        referencedTable: $state.db.bills,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$BillsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.bills, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$BillItemsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BillItemsTable> {
  $$BillItemsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get productId => $state.composableBuilder(
      column: $state.table.productId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get productName => $state.composableBuilder(
      column: $state.table.productName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get unitPrice => $state.composableBuilder(
      column: $state.table.unitPrice,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get discountAmount => $state.composableBuilder(
      column: $state.table.discountAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get gstRate => $state.composableBuilder(
      column: $state.table.gstRate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get gstAmount => $state.composableBuilder(
      column: $state.table.gstAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get taxableValue => $state.composableBuilder(
      column: $state.table.taxableValue,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get cgstAmount => $state.composableBuilder(
      column: $state.table.cgstAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get sgstAmount => $state.composableBuilder(
      column: $state.table.sgstAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get igstAmount => $state.composableBuilder(
      column: $state.table.igstAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get totalAmount => $state.composableBuilder(
      column: $state.table.totalAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$BillsTableOrderingComposer get billId {
    final $$BillsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.billId,
        referencedTable: $state.db.bills,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$BillsTableOrderingComposer(
            ComposerState(
                $state.db, $state.db.bills, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$BillEditsTableCreateCompanionBuilder = BillEditsCompanion Function({
  Value<int> id,
  required int billId,
  Value<DateTime> editedAt,
  required double previousTotal,
  required double newTotal,
  Value<String?> reasonNotes,
  required String changesJson,
});
typedef $$BillEditsTableUpdateCompanionBuilder = BillEditsCompanion Function({
  Value<int> id,
  Value<int> billId,
  Value<DateTime> editedAt,
  Value<double> previousTotal,
  Value<double> newTotal,
  Value<String?> reasonNotes,
  Value<String> changesJson,
});

class $$BillEditsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BillEditsTable,
    BillEdit,
    $$BillEditsTableFilterComposer,
    $$BillEditsTableOrderingComposer,
    $$BillEditsTableCreateCompanionBuilder,
    $$BillEditsTableUpdateCompanionBuilder> {
  $$BillEditsTableTableManager(_$AppDatabase db, $BillEditsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BillEditsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BillEditsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> billId = const Value.absent(),
            Value<DateTime> editedAt = const Value.absent(),
            Value<double> previousTotal = const Value.absent(),
            Value<double> newTotal = const Value.absent(),
            Value<String?> reasonNotes = const Value.absent(),
            Value<String> changesJson = const Value.absent(),
          }) =>
              BillEditsCompanion(
            id: id,
            billId: billId,
            editedAt: editedAt,
            previousTotal: previousTotal,
            newTotal: newTotal,
            reasonNotes: reasonNotes,
            changesJson: changesJson,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int billId,
            Value<DateTime> editedAt = const Value.absent(),
            required double previousTotal,
            required double newTotal,
            Value<String?> reasonNotes = const Value.absent(),
            required String changesJson,
          }) =>
              BillEditsCompanion.insert(
            id: id,
            billId: billId,
            editedAt: editedAt,
            previousTotal: previousTotal,
            newTotal: newTotal,
            reasonNotes: reasonNotes,
            changesJson: changesJson,
          ),
        ));
}

class $$BillEditsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BillEditsTable> {
  $$BillEditsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get editedAt => $state.composableBuilder(
      column: $state.table.editedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get previousTotal => $state.composableBuilder(
      column: $state.table.previousTotal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get newTotal => $state.composableBuilder(
      column: $state.table.newTotal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get reasonNotes => $state.composableBuilder(
      column: $state.table.reasonNotes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get changesJson => $state.composableBuilder(
      column: $state.table.changesJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$BillsTableFilterComposer get billId {
    final $$BillsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.billId,
        referencedTable: $state.db.bills,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$BillsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.bills, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$BillEditsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BillEditsTable> {
  $$BillEditsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get editedAt => $state.composableBuilder(
      column: $state.table.editedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get previousTotal => $state.composableBuilder(
      column: $state.table.previousTotal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get newTotal => $state.composableBuilder(
      column: $state.table.newTotal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get reasonNotes => $state.composableBuilder(
      column: $state.table.reasonNotes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get changesJson => $state.composableBuilder(
      column: $state.table.changesJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$BillsTableOrderingComposer get billId {
    final $$BillsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.billId,
        referencedTable: $state.db.bills,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$BillsTableOrderingComposer(
            ComposerState(
                $state.db, $state.db.bills, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  required String title,
  required double amount,
  Value<String> category,
  required DateTime date,
  Value<String?> notes,
  Value<bool> isDeleted,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<double> amount,
  Value<String> category,
  Value<DateTime> date,
  Value<String?> notes,
  Value<bool> isDeleted,
});

class $$ExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder> {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ExpensesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ExpensesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              ExpensesCompanion(
            id: id,
            title: title,
            amount: amount,
            category: category,
            date: date,
            notes: notes,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            required double amount,
            Value<String> category = const Value.absent(),
            required DateTime date,
            Value<String?> notes = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              ExpensesCompanion.insert(
            id: id,
            title: title,
            amount: amount,
            category: category,
            date: date,
            notes: notes,
            isDeleted: isDeleted,
          ),
        ));
}

class $$ExpensesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ExpensesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$DayClosingsTableCreateCompanionBuilder = DayClosingsCompanion
    Function({
  Value<int> id,
  required DateTime date,
  Value<double> openingCash,
  Value<double> cashSales,
  Value<double> returnsAmount,
  Value<double> cashExpenses,
  Value<double> expectedCash,
  Value<double> countedCash,
  Value<double> difference,
  Value<String?> notes,
  Value<DateTime> closedAt,
});
typedef $$DayClosingsTableUpdateCompanionBuilder = DayClosingsCompanion
    Function({
  Value<int> id,
  Value<DateTime> date,
  Value<double> openingCash,
  Value<double> cashSales,
  Value<double> returnsAmount,
  Value<double> cashExpenses,
  Value<double> expectedCash,
  Value<double> countedCash,
  Value<double> difference,
  Value<String?> notes,
  Value<DateTime> closedAt,
});

class $$DayClosingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DayClosingsTable,
    DayClosing,
    $$DayClosingsTableFilterComposer,
    $$DayClosingsTableOrderingComposer,
    $$DayClosingsTableCreateCompanionBuilder,
    $$DayClosingsTableUpdateCompanionBuilder> {
  $$DayClosingsTableTableManager(_$AppDatabase db, $DayClosingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DayClosingsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DayClosingsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<double> openingCash = const Value.absent(),
            Value<double> cashSales = const Value.absent(),
            Value<double> returnsAmount = const Value.absent(),
            Value<double> cashExpenses = const Value.absent(),
            Value<double> expectedCash = const Value.absent(),
            Value<double> countedCash = const Value.absent(),
            Value<double> difference = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> closedAt = const Value.absent(),
          }) =>
              DayClosingsCompanion(
            id: id,
            date: date,
            openingCash: openingCash,
            cashSales: cashSales,
            returnsAmount: returnsAmount,
            cashExpenses: cashExpenses,
            expectedCash: expectedCash,
            countedCash: countedCash,
            difference: difference,
            notes: notes,
            closedAt: closedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            Value<double> openingCash = const Value.absent(),
            Value<double> cashSales = const Value.absent(),
            Value<double> returnsAmount = const Value.absent(),
            Value<double> cashExpenses = const Value.absent(),
            Value<double> expectedCash = const Value.absent(),
            Value<double> countedCash = const Value.absent(),
            Value<double> difference = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> closedAt = const Value.absent(),
          }) =>
              DayClosingsCompanion.insert(
            id: id,
            date: date,
            openingCash: openingCash,
            cashSales: cashSales,
            returnsAmount: returnsAmount,
            cashExpenses: cashExpenses,
            expectedCash: expectedCash,
            countedCash: countedCash,
            difference: difference,
            notes: notes,
            closedAt: closedAt,
          ),
        ));
}

class $$DayClosingsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DayClosingsTable> {
  $$DayClosingsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get openingCash => $state.composableBuilder(
      column: $state.table.openingCash,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get cashSales => $state.composableBuilder(
      column: $state.table.cashSales,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get returnsAmount => $state.composableBuilder(
      column: $state.table.returnsAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get cashExpenses => $state.composableBuilder(
      column: $state.table.cashExpenses,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get expectedCash => $state.composableBuilder(
      column: $state.table.expectedCash,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get countedCash => $state.composableBuilder(
      column: $state.table.countedCash,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get difference => $state.composableBuilder(
      column: $state.table.difference,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get closedAt => $state.composableBuilder(
      column: $state.table.closedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DayClosingsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DayClosingsTable> {
  $$DayClosingsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get openingCash => $state.composableBuilder(
      column: $state.table.openingCash,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get cashSales => $state.composableBuilder(
      column: $state.table.cashSales,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get returnsAmount => $state.composableBuilder(
      column: $state.table.returnsAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get cashExpenses => $state.composableBuilder(
      column: $state.table.cashExpenses,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get expectedCash => $state.composableBuilder(
      column: $state.table.expectedCash,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get countedCash => $state.composableBuilder(
      column: $state.table.countedCash,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get difference => $state.composableBuilder(
      column: $state.table.difference,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get closedAt => $state.composableBuilder(
      column: $state.table.closedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$StoreSettingsTableCreateCompanionBuilder = StoreSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$StoreSettingsTableUpdateCompanionBuilder = StoreSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$StoreSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StoreSettingsTable,
    StoreSetting,
    $$StoreSettingsTableFilterComposer,
    $$StoreSettingsTableOrderingComposer,
    $$StoreSettingsTableCreateCompanionBuilder,
    $$StoreSettingsTableUpdateCompanionBuilder> {
  $$StoreSettingsTableTableManager(_$AppDatabase db, $StoreSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$StoreSettingsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$StoreSettingsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StoreSettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              StoreSettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
        ));
}

class $$StoreSettingsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $StoreSettingsTable> {
  $$StoreSettingsTableFilterComposer(super.$state);
  ColumnFilters<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$StoreSettingsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $StoreSettingsTable> {
  $$StoreSettingsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$ProductVariantsTableCreateCompanionBuilder = ProductVariantsCompanion
    Function({
  Value<int> id,
  required int productId,
  Value<String> variantName,
  required double price,
  Value<double> costPrice,
  Value<String?> sku,
  Value<bool> isDefault,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$ProductVariantsTableUpdateCompanionBuilder = ProductVariantsCompanion
    Function({
  Value<int> id,
  Value<int> productId,
  Value<String> variantName,
  Value<double> price,
  Value<double> costPrice,
  Value<String?> sku,
  Value<bool> isDefault,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$ProductVariantsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductVariantsTable,
    ProductVariant,
    $$ProductVariantsTableFilterComposer,
    $$ProductVariantsTableOrderingComposer,
    $$ProductVariantsTableCreateCompanionBuilder,
    $$ProductVariantsTableUpdateCompanionBuilder> {
  $$ProductVariantsTableTableManager(
      _$AppDatabase db, $ProductVariantsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ProductVariantsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ProductVariantsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> productId = const Value.absent(),
            Value<String> variantName = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<double> costPrice = const Value.absent(),
            Value<String?> sku = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ProductVariantsCompanion(
            id: id,
            productId: productId,
            variantName: variantName,
            price: price,
            costPrice: costPrice,
            sku: sku,
            isDefault: isDefault,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int productId,
            Value<String> variantName = const Value.absent(),
            required double price,
            Value<double> costPrice = const Value.absent(),
            Value<String?> sku = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ProductVariantsCompanion.insert(
            id: id,
            productId: productId,
            variantName: variantName,
            price: price,
            costPrice: costPrice,
            sku: sku,
            isDefault: isDefault,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$ProductVariantsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ProductVariantsTable> {
  $$ProductVariantsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get variantName => $state.composableBuilder(
      column: $state.table.variantName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get price => $state.composableBuilder(
      column: $state.table.price,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get costPrice => $state.composableBuilder(
      column: $state.table.costPrice,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sku => $state.composableBuilder(
      column: $state.table.sku,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDefault => $state.composableBuilder(
      column: $state.table.isDefault,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $state.db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProductsTableFilterComposer(ComposerState(
                $state.db, $state.db.products, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter productBarcodesRefs(
      ComposableFilter Function($$ProductBarcodesTableFilterComposer f) f) {
    final $$ProductBarcodesTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.productBarcodes,
            getReferencedColumn: (t) => t.variantId,
            builder: (joinBuilder, parentComposers) =>
                $$ProductBarcodesTableFilterComposer(ComposerState($state.db,
                    $state.db.productBarcodes, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$ProductVariantsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ProductVariantsTable> {
  $$ProductVariantsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get variantName => $state.composableBuilder(
      column: $state.table.variantName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get price => $state.composableBuilder(
      column: $state.table.price,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get costPrice => $state.composableBuilder(
      column: $state.table.costPrice,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sku => $state.composableBuilder(
      column: $state.table.sku,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDefault => $state.composableBuilder(
      column: $state.table.isDefault,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $state.db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProductsTableOrderingComposer(ComposerState(
                $state.db, $state.db.products, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$ProductBarcodesTableCreateCompanionBuilder = ProductBarcodesCompanion
    Function({
  Value<int> id,
  Value<int?> variantId,
  required int productId,
  required String barcode,
  Value<bool> isPrimary,
  Value<DateTime> createdAt,
});
typedef $$ProductBarcodesTableUpdateCompanionBuilder = ProductBarcodesCompanion
    Function({
  Value<int> id,
  Value<int?> variantId,
  Value<int> productId,
  Value<String> barcode,
  Value<bool> isPrimary,
  Value<DateTime> createdAt,
});

class $$ProductBarcodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductBarcodesTable,
    ProductBarcode,
    $$ProductBarcodesTableFilterComposer,
    $$ProductBarcodesTableOrderingComposer,
    $$ProductBarcodesTableCreateCompanionBuilder,
    $$ProductBarcodesTableUpdateCompanionBuilder> {
  $$ProductBarcodesTableTableManager(
      _$AppDatabase db, $ProductBarcodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ProductBarcodesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ProductBarcodesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> variantId = const Value.absent(),
            Value<int> productId = const Value.absent(),
            Value<String> barcode = const Value.absent(),
            Value<bool> isPrimary = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ProductBarcodesCompanion(
            id: id,
            variantId: variantId,
            productId: productId,
            barcode: barcode,
            isPrimary: isPrimary,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> variantId = const Value.absent(),
            required int productId,
            required String barcode,
            Value<bool> isPrimary = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ProductBarcodesCompanion.insert(
            id: id,
            variantId: variantId,
            productId: productId,
            barcode: barcode,
            isPrimary: isPrimary,
            createdAt: createdAt,
          ),
        ));
}

class $$ProductBarcodesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ProductBarcodesTable> {
  $$ProductBarcodesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get barcode => $state.composableBuilder(
      column: $state.table.barcode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isPrimary => $state.composableBuilder(
      column: $state.table.isPrimary,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProductVariantsTableFilterComposer get variantId {
    final $$ProductVariantsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.variantId,
            referencedTable: $state.db.productVariants,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$ProductVariantsTableFilterComposer(ComposerState($state.db,
                    $state.db.productVariants, joinBuilder, parentComposers)));
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $state.db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProductsTableFilterComposer(ComposerState(
                $state.db, $state.db.products, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$ProductBarcodesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ProductBarcodesTable> {
  $$ProductBarcodesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get barcode => $state.composableBuilder(
      column: $state.table.barcode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isPrimary => $state.composableBuilder(
      column: $state.table.isPrimary,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProductVariantsTableOrderingComposer get variantId {
    final $$ProductVariantsTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.variantId,
            referencedTable: $state.db.productVariants,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$ProductVariantsTableOrderingComposer(ComposerState($state.db,
                    $state.db.productVariants, joinBuilder, parentComposers)));
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $state.db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProductsTableOrderingComposer(ComposerState(
                $state.db, $state.db.products, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$UnmatchedScansTableCreateCompanionBuilder = UnmatchedScansCompanion
    Function({
  Value<int> id,
  required String barcode,
  Value<int> scanCount,
  Value<DateTime> lastScannedAt,
  Value<DateTime> createdAt,
});
typedef $$UnmatchedScansTableUpdateCompanionBuilder = UnmatchedScansCompanion
    Function({
  Value<int> id,
  Value<String> barcode,
  Value<int> scanCount,
  Value<DateTime> lastScannedAt,
  Value<DateTime> createdAt,
});

class $$UnmatchedScansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UnmatchedScansTable,
    UnmatchedScan,
    $$UnmatchedScansTableFilterComposer,
    $$UnmatchedScansTableOrderingComposer,
    $$UnmatchedScansTableCreateCompanionBuilder,
    $$UnmatchedScansTableUpdateCompanionBuilder> {
  $$UnmatchedScansTableTableManager(
      _$AppDatabase db, $UnmatchedScansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$UnmatchedScansTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$UnmatchedScansTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> barcode = const Value.absent(),
            Value<int> scanCount = const Value.absent(),
            Value<DateTime> lastScannedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              UnmatchedScansCompanion(
            id: id,
            barcode: barcode,
            scanCount: scanCount,
            lastScannedAt: lastScannedAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String barcode,
            Value<int> scanCount = const Value.absent(),
            Value<DateTime> lastScannedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              UnmatchedScansCompanion.insert(
            id: id,
            barcode: barcode,
            scanCount: scanCount,
            lastScannedAt: lastScannedAt,
            createdAt: createdAt,
          ),
        ));
}

class $$UnmatchedScansTableFilterComposer
    extends FilterComposer<_$AppDatabase, $UnmatchedScansTable> {
  $$UnmatchedScansTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get barcode => $state.composableBuilder(
      column: $state.table.barcode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get scanCount => $state.composableBuilder(
      column: $state.table.scanCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastScannedAt => $state.composableBuilder(
      column: $state.table.lastScannedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$UnmatchedScansTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $UnmatchedScansTable> {
  $$UnmatchedScansTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get barcode => $state.composableBuilder(
      column: $state.table.barcode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get scanCount => $state.composableBuilder(
      column: $state.table.scanCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastScannedAt => $state.composableBuilder(
      column: $state.table.lastScannedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db, _db.units);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$BillsTableTableManager get bills =>
      $$BillsTableTableManager(_db, _db.bills);
  $$BillItemsTableTableManager get billItems =>
      $$BillItemsTableTableManager(_db, _db.billItems);
  $$BillEditsTableTableManager get billEdits =>
      $$BillEditsTableTableManager(_db, _db.billEdits);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$DayClosingsTableTableManager get dayClosings =>
      $$DayClosingsTableTableManager(_db, _db.dayClosings);
  $$StoreSettingsTableTableManager get storeSettings =>
      $$StoreSettingsTableTableManager(_db, _db.storeSettings);
  $$ProductVariantsTableTableManager get productVariants =>
      $$ProductVariantsTableTableManager(_db, _db.productVariants);
  $$ProductBarcodesTableTableManager get productBarcodes =>
      $$ProductBarcodesTableTableManager(_db, _db.productBarcodes);
  $$UnmatchedScansTableTableManager get unmatchedScans =>
      $$UnmatchedScansTableTableManager(_db, _db.unmatchedScans);
}
