
import SwiftUI

// MARK: - Modelos

struct WorkoutSet: Identifiable, Codable, Equatable {
    var id = UUID()
    var weight: Double = 0
    var reps: Int = 10
}

struct Exercise: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var sets: [WorkoutSet] = [
        WorkoutSet(),
        WorkoutSet(),
        WorkoutSet()
    ]
}

// MARK: - Almacenamiento local

final class WorkoutStore: ObservableObject {
    @Published var exercises: [Exercise] = [] {
        didSet {
            save()
        }
    }

    private let storageKey = "gymTracker.exercises"

    init() {
        load()
    }

    func addExercise(name: String) {
        let cleanedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanedName.isEmpty else { return }

        exercises.append(Exercise(name: cleanedName))
    }

    func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(exercises) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let savedExercises = try? JSONDecoder().decode(
                [Exercise].self,
                from: data
            )
        else {
            exercises = [
                Exercise(name: "Press de banca"),
                Exercise(name: "Jalón al pecho"),
                Exercise(name: "Curl de bíceps")
            ]
            return
        }

        exercises = savedExercises
    }
}

// MARK: - Aplicación

@main
struct GymTrackerApp: App {
    @StateObject private var store = WorkoutStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

// MARK: - Pantalla principal

struct ContentView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var showingAddExercise = false
    @State private var newExerciseName = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($store.exercises) { $exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: $exercise)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(exercise.name)
                                    .font(.headline)

                                Text(
                                    "\(exercise.sets.count) series"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: store.deleteExercise)
                } header: {
                    Text("Mis ejercicios")
                } footer: {
                    Text(
                        "Desliza un ejercicio hacia la izquierda para eliminarlo."
                    )
                }
            }
            .navigationTitle("Mi gimnasio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newExerciseName = ""
                        showingAddExercise = true
                    } label: {
                        Label("Añadir", systemImage: "plus")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .alert("Nuevo ejercicio", isPresented: $showingAddExercise) {
                TextField("Nombre del ejercicio", text: $newExerciseName)

                Button("Cancelar", role: .cancel) {}

                Button("Añadir") {
                    store.addExercise(name: newExerciseName)
                }
            } message: {
                Text("Introduce el nombre del ejercicio.")
            }
        }
    }
}

// MARK: - Detalle del ejercicio

struct ExerciseDetailView: View {
    @Binding var exercise: Exercise

    var body: some View {
        List {
            Section {
                Text(exercise.name)
                    .font(.title3.bold())
            }

            Section {
                HStack {
                    Text("Serie")
                        .frame(width: 55, alignment: .leading)

                    Spacer(minLength: 8)

                    Text("Peso (kg)")
                        .frame(width: 100)

                    Text("Reps.")
                        .frame(width: 65)
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)

                ForEach($exercise.sets) { $set in
                    HStack {
                        Text("\(exercise.sets.firstIndex(
                            where: { $0.id == set.id }
                        ).map { $0 + 1 } ?? 0)")
                        .frame(width: 55, alignment: .leading)

                        Spacer(minLength: 8)

                        TextField(
                            "0",
                            value: $set.weight,
                            format: .number.precision(.fractionLength(0...2))
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)

                        TextField(
                            "0",
                            value: $set.reps,
                            format: .number
                        )
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 65)
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .onDelete { offsets in
                    exercise.sets.remove(atOffsets: offsets)
                }

                Button {
                    exercise.sets.append(WorkoutSet())
                } label: {
                    Label("Añadir serie", systemImage: "plus.circle")
                }
            } header: {
                Text("Series y repeticiones")
            } footer: {
                Text("Introduce el peso utilizado y las repeticiones realizadas.")
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
    }
}
