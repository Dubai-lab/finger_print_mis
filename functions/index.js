const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

// Cloud Function to clean up expired pending course offerings for students
// eslint-disable-next-line max-len
exports.cleanupExpiredPendingCourses = functions.pubsub.schedule("every 1 hours").onRun(async (context) => {
  const now = admin.firestore.Timestamp.now();
  // eslint-disable-next-line max-len
  const cutoff = new Date(now.toDate().getTime() - 48 * 60 * 60 * 1000); // 48 hours ago

  const courseOfferingsSnapshot = await db.collection("course_offerings").get();

  for (const doc of courseOfferingsSnapshot.docs) {
    const data = doc.data();
    const pendingStudents = data.pendingStudents || {};
    // eslint-disable-next-line max-len
    const joinedStudents = data.joinedStudents || []; // Assuming you track joined students here

    let updated = false;
    const newPendingStudents = {};

    for (const [studentId, sentTimestamp] of Object.entries(pendingStudents)) {
      // eslint-disable-next-line max-len
      const sentDate = sentTimestamp.toDate ? sentTimestamp.toDate() : new Date(sentTimestamp);
      if (sentDate < cutoff) {
        // Check if student has joined, if not remove from pending
        if (!joinedStudents.includes(studentId)) {
          updated = true;
          // Do not add to newPendingStudents to remove
        } else {
          newPendingStudents[studentId] = sentTimestamp;
        }
      } else {
        newPendingStudents[studentId] = sentTimestamp;
      }
    }

    if (updated) {
      await doc.ref.update({
        pendingStudents: newPendingStudents,
      });
      // eslint-disable-next-line max-len
      console.log(`Cleaned up expired pending students for course offering ${doc.id}`);
    }
  }

  return null;
});
