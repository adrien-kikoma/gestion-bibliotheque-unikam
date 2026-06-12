// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emprunt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmpruntAdapter extends TypeAdapter<Emprunt> {
  @override
  final int typeId = 2;

  @override
  Emprunt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Emprunt(
      id: fields[0] as String,
      livreId: fields[1] as String,
      utilisateurId: fields[2] as String,
      dateEmprunt: fields[3] as DateTime,
      dateRetourPrevue: fields[4] as DateTime,
      dateRetourReel: fields[5] as DateTime?,
      statut: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Emprunt obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.livreId)
      ..writeByte(2)
      ..write(obj.utilisateurId)
      ..writeByte(3)
      ..write(obj.dateEmprunt)
      ..writeByte(4)
      ..write(obj.dateRetourPrevue)
      ..writeByte(5)
      ..write(obj.dateRetourReel)
      ..writeByte(6)
      ..write(obj.statut);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmpruntAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
