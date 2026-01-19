// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pet_breed_selection_page.dart';
import 'pet_type_selection_page.dart';
import 'pet_weight_selection_page.dart';
import 'service_date_page.dart';
import '../services/pet_profile_service.dart';

class PetProfilePage extends StatefulWidget {
  final bool fromRequestPage;
  final String? serviceName;

  const PetProfilePage({
    super.key,
    this.fromRequestPage = false,
    this.serviceName,
  });

  @override
  State<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage> {
  List<Map<String, dynamic>> pets = [];
  Set<int> selectedIndexes = {};
  final PetProfileService _petProfileService = PetProfileService();
  bool _isLoadingBackend = true;

  @override
  void initState() {
    super.initState();
    _loadPetsFromBackend();
  }

  bool get isNextButtonActive => selectedIndexes.isNotEmpty;

  //---------------- BACKEND ----------------

  Future<void> _loadPetsFromBackend() async {
    setState(() {
      _isLoadingBackend = true;
    });
    try {
      final backendPets = await _petProfileService.getMyPets();
      pets = backendPets.map<Map<String, dynamic>>((pet) {
        final type = pet.species;
        return {
          "id": pet.id,
          "type": type,
          "breed": pet.breed ?? '',
          "weight": pet.weight ?? (pet.age != null ? "${pet.age} Kg" : "Kilo Bilinmiyor"),
          "name": pet.name,
          "ownerName": pet.ownerName,
          "ownerContact": pet.ownerContact,
          "color": getPetColor(type),
          "icon": getPetIcon(type),
        };
      }).toList();
    } catch (e) {
      // Hata yönetimi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet profilleri yüklenirken bir hata oluştu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      pets = [];
    } finally {
      setState(() {
        _isLoadingBackend = false;
      });
    }
  }
  void _handleSelect(int index) {
    setState(() {
      selectedIndexes.contains(index)
          ? selectedIndexes.remove(index)
          : selectedIndexes.add(index);
    });
  }

  Future<void> _deletePet(int index) async {
    final pet = pets[index];
    final petId = pet['id'] as String?;

    // Backend'den sil
    if (petId != null) {
      final success = await _petProfileService.deletePet(petId);
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pet profili silinirken bir hata oluştu.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // UI'dan kaldır
    setState(() {
      pets.removeAt(index);
      selectedIndexes.remove(index);
      selectedIndexes = selectedIndexes.map((i) => i > index ? i - 1 : i).toSet();
    });
  }

  //---------------- EDIT PET ----------------//

  Future<void> _editPet(int index) async {
    final type = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PetTypeSelectionPage(),
      ),
    );

    if (type != null) {
      final breed = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PetBreedSelectionPage(petType: type),
        ),
      );

      if (breed != null) {
        final weight = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PetWeightSelectionPage(
              petType: type,
              breed: breed,
            ),
          ),
        );

        if (weight != null) {
          final pet = pets[index];
          final String petId = pet['id']?.toString() ?? '';
          
          if (petId.isNotEmpty) {
            try {
              await _petProfileService.updatePet(
                id: petId,
                name: pet['name']?.toString() ?? type,
                species: type,
                breed: breed,
                weight: weight,
                age: null,
                vaccinationStatus: null,
                healthNotes: null,
                ownerName: pet['ownerName']?.toString() ?? "Bilinmiyor",
                ownerContact: pet['ownerContact']?.toString() ?? "Bilinmiyor",
              );
            } catch (e) {
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Güncelleme hatası: $e")));
              }
            }
          }

          setState(() {
            pets[index] = {
              ...pet,
              "type": type,
              "breed": breed,
              "weight": weight,
              "color": getPetColor(type),
              "icon": getPetIcon(type),
            };
          });
        }
      }
    }
  }

  //-------------------- NAME FOR DISPLAY (DÜZELTİLEN KISIM) --------------------//

  String _getPetDisplayName(Map<String, dynamic> pet) {
    final name = pet['name']?.toString() ?? '';
    final species = pet['type']?.toString() ?? '';

    const petTypeTranslations = {
      "Dog": "Köpek",
      "Cat": "Kedi",
      "Rabbit": "Tavşan",
      "Bird": "Kuş",
      "Fish": "Balık",
      "Other": "Diğer",
      "Köpek": "Köpek",
      "Kedi": "Kedi",
      "Tavşan": "Tavşan",
      "Kuş": "Kuş",
      "Balık": "Balık",
      "Diğer": "Diğer",
    };

    if (name.isEmpty || name == "Bilinmiyor") {
      return petTypeTranslations[species] ?? species;
    }
    return name;
  }

  //---------------- UI ----------------//

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB39DDB), Color(0xFFF48FB1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // APP BAR
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        const Text(
                          "Hayvanlarım",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        widget.fromRequestPage
                            ? IconButton(
                                icon: const Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                ),
                                onPressed: _showInfoDialog,
                              )
                            : const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Kayıtlı Evcil Hayvanlarım",
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            // REQUEST PAGE İSE BİLGİ UYARISI
                            if (widget.fromRequestPage)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PetProfilePage(
                                          fromRequestPage: false,
                                          serviceName: widget.serviceName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Yeni hayvan eklemek / düzenlemek için\nHayvanlarım sayfasına gitmek için tıklayın",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.deepPurple,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),

                            // PET LIST
                            Expanded(
                              child: _isLoadingBackend
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : ListView.builder(
                                      itemCount: widget.fromRequestPage
                                          ? pets.length
                                          : pets.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index < pets.length) {
                                          final pet = pets[index];
                                          final isSelected =
                                              selectedIndexes.contains(index);

                                          return GestureDetector(
                                            onTap: () => _handleSelect(index),
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 12),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: isSelected
                                                    ? Border.all(
                                                        color:
                                                            Colors.deepPurple,
                                                        width: 2)
                                                    : null,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.05),
                                                    blurRadius: 6,
                                                    offset:
                                                        const Offset(0, 4),
                                                  ),
                                                ],
                                                color: Colors.white,
                                              ),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 28,
                                                    backgroundColor:
                                                        pet['color'],
                                                    child: Icon(
                                                      pet['icon'],
                                                      color: Colors.white,
                                                      size: 26,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          _getPetDisplayName(
                                                              pet),
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        if (pet['breed'] !=
                                                                null &&
                                                            pet['breed']
                                                                .toString()
                                                                .isNotEmpty)
                                                          Text(
                                                              "Irk: ${pet['breed']}"),
                                                        Text(pet['weight'] ??
                                                            "Bilinmiyor"),
                                                      ],
                                                    ),
                                                  ),

                                                  widget.fromRequestPage
                                                      ? Icon(
                                                          isSelected
                                                              ? Icons
                                                                  .check_circle
                                                              : Icons
                                                                  .circle_outlined,
                                                          color: isSelected
                                                              ? Colors
                                                                  .deepPurple
                                                              : Colors.grey,
                                                        )
                                                      : Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              icon:
                                                                  const Icon(
                                                                Icons.edit,
                                                                color: Colors
                                                                    .deepPurple,
                                                              ),
                                                              onPressed: () =>
                                                                  _editPet(
                                                                      index),
                                                            ),
                                                            IconButton(
                                                              icon:
                                                                  const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                              onPressed: () =>
                                                                  _deletePet(
                                                                      index),
                                                            ),
                                                          ],
                                                        ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }

                                        // ADD NEW PET BUTTON
                                        return GestureDetector(
                                          onTap: () async {
                                            final type = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PetTypeSelectionPage(),
                                              ),
                                            );

                                            if (type != null) {
                                              final breed =
                                                  await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      PetBreedSelectionPage(
                                                    petType: type,
                                                  ),
                                                ),
                                              );

                                              if (breed != null) {
                                                final weight =
                                                    await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        PetWeightSelectionPage(
                                                      petType: type,
                                                      breed: breed,
                                                    ),
                                                  ),
                                                );

                                                if (weight != null) {
                                                  try {
                                                    final prefs = await SharedPreferences.getInstance();
                                                    final storedId = prefs.get('userId');
                                                    final userId = storedId?.toString() ?? "";
                                                    final result =
                                                      await _petProfileService
                                                        .createPet(
                                                        userId: userId.toString(),
                                                        name: type.toString(),
                                                        species: type.toString(),
                                                        breed: breed.toString(),
                                                        age: null,
                                                        weight: weight.toString(),
                                                        vaccinationStatus: null,
                                                        healthNotes: null,
                                                        ownerName: "Bilinmiyor",
                                                        ownerContact: "Bilinmiyor",
                                                      );
                                                    if (result["success"] ==
                                                            true ||
                                                        result["id"] != null) {
                                                      await _loadPetsFromBackend();
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              "Hayvan kaydedilemedi: ${result["message"] ?? "Bilinmeyen hata"}"),
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              "Sunucu hatası: $e")),
                                                    );
                                                  }
                                                }
                                              }
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                  color: Colors.deepPurple),
                                              color: Colors.grey.shade50,
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.add,
                                                    color: Colors.deepPurple),
                                                SizedBox(width: 12),
                                                Text(
                                                  "Yeni Evcil Hayvan Ekle",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.deepPurple),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),

                            // NEXT BUTTON
                            if (widget.fromRequestPage)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: GestureDetector(
                                  onTap: isNextButtonActive
                                      ? () {
                                          final selectedPet = pets[
                                              selectedIndexes.first];

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ServiceDatePage(
                                                petName: selectedPet['type'],
                                                serviceName:
                                                    widget.serviceName ??
                                                        "Pansiyon",
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    decoration: BoxDecoration(
                                      color: isNextButtonActive
                                          ? Colors.deepPurple
                                          : Colors.grey,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "İleri",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  //------------------ INFO DIALOG ------------------//

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.deepPurple,
              child: Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Bilgi",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Yeni hayvan eklemek veya düzenlemek için Hayvanlarım sayfasına gitmelisiniz.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PetProfilePage(
                      fromRequestPage: false,
                      serviceName: widget.serviceName,
                    ),
                  ),
                ).then((_) {
                  _loadPetsFromBackend();
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple],
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Hayvanlarım Sayfasına Git",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Vazgeç",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

//--- PET COLOR & ICON HELPERS ---//
  Color getPetColor(String type) {
    switch (type) {
      case 'Köpek':
        return Colors.orange;
      case 'Kedi':
        return Colors.redAccent;
      case 'Kuş':
        return Colors.lightBlue;
      case 'Tavşan':
        return Colors.green;
      case 'Balık':
        return Colors.cyan;
      default:
        return Colors.purpleAccent;
    }
  }

  IconData getPetIcon(String type) {
    return Icons.pets;
  }
}
