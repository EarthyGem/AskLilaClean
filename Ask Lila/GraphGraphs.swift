
import Firebase
import FirebaseFirestore


class ChartRefiner {
    static let shared = ChartRefiner()
    private init() {}

    func mergeNewHouseSignifications(for house: Int, newSigs: [String], uid: String) {
        ChartContextManager.shared.updateHouseSignifications(house, significations: newSigs, for: uid)
    }

    func updatePlanetArchetypes(_ archetypes: [String], uid: String) {
        let update: [String: Any] = [
            "planetArchetypes": FieldValue.arrayUnion(archetypes)
        ]
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("chartContext")
            .document("summary")
            .setData(update, merge: true)
    }
}
