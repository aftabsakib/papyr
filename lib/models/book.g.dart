// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 0;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String?,
      format: fields[3] as BookFormat,
      fileName: fields[4] as String,
      coverFileName: fields[5] as String?,
      pageCount: fields[6] as int?,
      progress: fields[7] as double,
      locator: fields[8] as String?,
      addedAt: fields[9] as DateTime,
      lastOpenedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.format)
      ..writeByte(4)
      ..write(obj.fileName)
      ..writeByte(5)
      ..write(obj.coverFileName)
      ..writeByte(6)
      ..write(obj.pageCount)
      ..writeByte(7)
      ..write(obj.progress)
      ..writeByte(8)
      ..write(obj.locator)
      ..writeByte(9)
      ..write(obj.addedAt)
      ..writeByte(10)
      ..write(obj.lastOpenedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookFormatAdapter extends TypeAdapter<BookFormat> {
  @override
  final int typeId = 1;

  @override
  BookFormat read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BookFormat.pdf;
      case 1:
        return BookFormat.epub;
      default:
        return BookFormat.pdf;
    }
  }

  @override
  void write(BinaryWriter writer, BookFormat obj) {
    switch (obj) {
      case BookFormat.pdf:
        writer.writeByte(0);
        break;
      case BookFormat.epub:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookFormatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
