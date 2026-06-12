// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livre.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LivreAdapter extends TypeAdapter<Livre> {
  @override
  final int typeId = 0;

  @override
  Livre read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Livre(
      idLivre: fields[0] as String,
      titre: fields[1] as String,
      auteur: fields[2] as String,
      quantiteStock: fields[3] as int,
      domaine: fields[4] as String,
      edition: fields[5] as String,
      anneePublication: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Livre obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.idLivre)
      ..writeByte(1)
      ..write(obj.titre)
      ..writeByte(2)
      ..write(obj.auteur)
      ..writeByte(3)
      ..write(obj.quantiteStock)
      ..writeByte(4)
      ..write(obj.domaine)
      ..writeByte(5)
      ..write(obj.edition)
      ..writeByte(6)
      ..write(obj.anneePublication);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LivreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
