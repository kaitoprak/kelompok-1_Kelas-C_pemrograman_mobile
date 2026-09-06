String tentukanGrade(double nilai) {
  if (nilai >= 85) {
    return "A";
  } else if (nilai >= 75) {
    return "B";
  } else if (nilai >= 65) {
    return "C";
  } else if (nilai >= 50) {
    return "D";
  } else {
    return "E";
  }
}

String tentukanStatus(double nilai, double kehadiran) {
  if (nilai >= 65 && kehadiran >= 75) {
    return "LULUS";
  } else {
    return "TIDAK LULUS";
  }
}

void main() {
  List<Map<String, dynamic>> mahasiswa = [
    {
      "nama": "Andi",
      "nilai": 90.0,
      "kehadiran": 95.0,
    },
    {
      "nama": "Budi",
      "nilai": 78.0,
      "kehadiran": 85.0,
    },
    {
      "nama": "Citra",
      "nilai": 62.0,
      "kehadiran": 90.0,
    },
    {
      "nama": "Dina",
      "nilai": 88.0,
      "kehadiran": 70.0,
    },
    {
      "nama": "Eko",
      "nilai": 45.0,
      "kehadiran": 60.0,
    },
  ];

  print("======================================");
  print("       STUDENT GRADE TRACKER");
  print("======================================");

  for (var data in mahasiswa) {
    String nama = data["nama"];
    double nilai = data["nilai"];
    double kehadiran = data["kehadiran"];

    String grade = tentukanGrade(nilai);
    String status = tentukanStatus(nilai, kehadiran);

    print("\nNama       : $nama");
    print("Nilai      : $nilai");
    print("Kehadiran  : $kehadiran%");
    print("Grade      : $grade");
    print("Status     : $status");
    print("--------------------------------------");
  }
}