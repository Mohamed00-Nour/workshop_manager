const admin = require('firebase-admin');
const path = require('path');

// Read the service account key
const serviceAccountPath = path.join(__dirname, '../lib/assets/workshop-manager-5f2f7-1c915a4d22cd.json');
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const messaging = admin.messaging();

console.log("Secure FCM V1 notification listener started...");

// Listen to changes in the 'notifications' collection
db.collection('notifications')
  .where('status', '==', 'pending')
  .onSnapshot(snapshot => {
    snapshot.docChanges().forEach(async (change) => {
      if (change.type === 'added') {
        const doc = change.doc;
        const data = doc.data();
        const docId = doc.id;
        
        console.log(`New notification request received: ${docId}`);
        
        const message = {
          notification: {
            title: data.title,
            body: data.body,
          },
          android: {
            notification: {
              sound: 'default',
              clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            }
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
              }
            }
          }
        };

        if (data.token) {
          message.token = data.token;
        } else if (data.topic) {
          message.topic = data.topic;
        } else {
          message.topic = 'workshop_updates';
        }

        try {
          // Update status to sending to prevent double sending
          await doc.ref.update({ status: 'sending' });
          
          // Send notification via FCM V1
          const response = await messaging.send(message);
          console.log(`Successfully sent message: ${response}`);
          
          // Delete or mark document as completed to reduce storage cost
          await doc.ref.delete();
          console.log(`Deleted completed notification document: ${docId}`);
        } catch (error) {
          console.error(`Error sending message for ${docId}:`, error);
          await doc.ref.update({ 
            status: 'failed',
            error: error.message 
          });
        }
      }
    });
  });
