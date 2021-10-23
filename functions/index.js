// const functions = require("firebase-functions");
//
// const admin = require('firebase-admin');
// admin.initializeApp();

const functions = require('firebase-functions')
const admin = require('firebase-admin')
admin.initializeApp(functions.config().firebase)
const algoliasearch = require('algoliasearch')
const ALGOLIA_ID = functions.config().algolia.app_id
const ALGOLIA_ADMIN_KEY = functions.config().algolia.api_key
const ALGOLIA_SEARCH_KEY = functions.config().algolia.search_key
const ALGOLIA_INDEX_NAME = functions.config().algolia.index_name
const client = algoliasearch(ALGOLIA_ID, ALGOLIA_ADMIN_KEY)
const db = admin.firestore()
const arrayChunk = ([...array], size = 1) => {
return array.reduce((acc, value, index) => index % size ? acc : [...acc, array.slice(index, index + size)], []);
};



exports.createIndex =  functions.region("asia-northeast1").firestore.document('rooms/{roomID}').onCreate(async(snap, context) => {
const data = snap.data();
data.objectID = data.documentID;
// algoliaのindexへ追加
const index = client.initIndex(ALGOLIA_INDEX_NAME)
return index.saveObject(data)
});


exports.updateIndex =  functions.region("asia-northeast1").firestore.document('rooms/{roomID}').onUpdate(async(change, context) => {
  const newData = change.after.data();
  // const beforeData = change.before.data();
  newData.objectID = change.after.id;
  const index = client.initIndex(ALGOLIA_INDEX_NAME)
  return index.saveObject(newData);
  });

exports.deleteIndex =  functions.region("asia-northeast1").firestore.document('rooms/{roomID}').onDelete(async(snap, context) => {
  const deletedData = snap.data();
  const objectID = deletedData.documentID;
  const index = client.initIndex(ALGOLIA_INDEX_NAME)
  return index.deleteObject(objectID);
});




//ルームプロフィールを変更
exports.updateRoomDetail =  functions.region("asia-northeast1").firestore.document('rooms/{roomID}').onUpdate(async(change, context) => {
  const newData = change.after.data();
  const beforeData = change.before.data();
  const documentID = beforeData.documentID;

  if ((newData.roomName != beforeData.roomName) || (newData.roomImage != beforeData.roomImage)) {
    const users = await db.collection('rooms').doc(documentID).collection('members').get();
    const uids =  users.docs.map(user => {
      return user.data().uid;
    });
    for(const chunkedUsers of arrayChunk(uids,500)){
      const batch = db.batch();
      chunkedUsers.forEach(uid => {
        const userRef = db.collection('users').doc(uid).collection('rooms').doc(documentID);
        batch.update(userRef,{roomName:newData.roomName,roomImage:newData.roomImage});
      });
      await batch.commit();
    };
  }



});



//自分のプロフィールを変更
exports.updateUser =  functions.region("asia-northeast1").firestore.document('users/{userID}/rooms/{roomID}').onUpdate(async(change, context) => {
      const newData = change.after.data();
      const beforeData = change.before.data();
      const documentID = beforeData.documentID;
      const uid = beforeData.uid;

      if ((newData.userName != beforeData.userName) || (newData.userImage != beforeData.userImage)) {
        //postsのプロフィールを変更
        const snapShots = await db
        .collection('users').doc(uid).collection('rooms')
        .doc(documentID).collection('posts').get();
        const userContents = snapShots.docs.map(snap => {
          return snap.data().documentID;
        });
        for(const chunkedContents of arrayChunk(userContents,200)){
          const batch = db.batch();
          chunkedContents.forEach( data => {
            const contentRef = db.collection('users').doc(uid).collection('rooms').doc(documentID).collection('posts').doc(data);
            batch.update(contentRef,{userName:newData.userName,userImage:newData.userImage});
          });
          await batch.commit();
        };
        //mediaPostsのプロフィールを変更
        const mediaSnapShots = await db
        .collection('rooms').doc(documentID).collection('mediaPosts').where('uid','==',uid).get();
        const mediaContents = mediaSnapShots.docs.map(snap => {
          return snap.data().documentID;
        });
        for(const chunkedMediaContents of arrayChunk(mediaContents,200)){
          const batch = db.batch();
          chunkedMediaContents.forEach( data => {
            const mediaPostRef = db.collection('rooms').doc(documentID).collection('mediaPosts').doc(data);
            batch.update(mediaPostRef,{userName:newData.userName,userImage:newData.userImage});
          });
          await batch.commit();
        };
　　　　　//commentのプロフィールを変更
        const commentSnapshots = await db.collection('users').doc(uid).collection('rooms').doc(documentID).collection('comments').get();
        const comments = commentSnapshots.docs.map(snap => {
          return snap.data();
        });
        for(const chunkedComments of arrayChunk(comments,100)){
          const batch = db.batch();
          chunkedComments.forEach( data => {
            const commentRef = db.collection('users').doc(uid).collection('rooms').doc(documentID).collection('comments').doc(data.documentID);
            batch.update(commentRef,{userName:newData.userName,userImage:newData.userImage});
          });
          await batch.commit();
        }
      }else if (newData.isJoined == false){
        //ルーム退出時にそのルームのfeedsを削除
        const feedSnapShots = await db.collection('users').doc(uid).collection('feeds').where('roomID','==', documentID).get();
        const feeds = feedSnapShots.docs.map(snap => {
          return snap.data();
        });
        for(const chunkedFeeds of arrayChunk(feeds,500)){
          const batch = db.batch();
          chunkedFeeds.forEach( data => {
            const feedRef = db.collection('users').doc(uid).collection('feeds').doc(data.documentID);
            batch.delete(feedRef)
          });
          await batch.commit();
        }

      }
    });





exports.deletedModeratorPost = functions.region("asia-northeast1").firestore.document('rooms/{roomID}/moderatorPosts/{postID}')
.onDelete(async(snap, context) => {
  const deletedData = snap.data();
  const roomID = deletedData.roomID;
  const documentID = deletedData.documentID;
  const users = await db.collection('rooms').doc(roomID).collection('members').get();
  const uids =  users.docs.map(user => {
    return user.data().uid;
  });
  for(const chunkedUsers of arrayChunk(uids,500)){
    const batch = db.batch();
    chunkedUsers.forEach( uid => {
      const deleteRef = db.collection('users').doc(uid).collection('feeds').doc(documentID);
      batch.delete(deleteRef);
    });
    await batch.commit();
  };
});








exports.sendPushNotification = functions.region("asia-northeast1").firestore.document('users/{userID}/notifications/{notificationID}')
.onCreate(async(snap, context) => {
  const data = snap.data();
  const giverName = data.userName;
  const roomName = data.roomName;
  const category = data.category;
  const uid = context.params.userID;
  console.log(uid,category);
  const userRef = await admin
      .firestore()
      .collection('users')
      .doc(uid);
    const userDoc = await userRef.get();
    const user = userDoc.data();
      if (category == 'like'){
        const payload = {
        notification: {
          title: `${roomName}`,
          body: `${giverName}さんがあなたの投稿にいいねしました!`,
          sound: "default"
        }
      };
      admin.messaging().sendToDevice(user.fcmToken, payload);
      }else if (category == 'comment'){
        const payload = {
        notification: {
          title: `${roomName}`,
          body: `${giverName}さんがあなたの投稿にコメントしました!`
        }
      };
      admin.messaging().sendToDevice(user.fcmToken, payload);
      }

    return true;

});




exports.createFeeds = functions.region("asia-northeast1").firestore.document('rooms/{roomID}/moderatorPosts/{postID}')
.onCreate(async(snap, context) => {
  const data = snap.data();
  const documentID = data.documentID;
  const roomID = data.roomID;
  const createdAt = data.createdAt;
  const moderatorUid = data.uid;
  const users = await db.collection('rooms').doc(roomID).collection('members').get();
  const uids =  users.docs.map(user => {
    return user.data().uid;
  });
  for(const chunkedUsers of arrayChunk(uids,500)){
    const batch = db.batch();
    chunkedUsers.forEach( uid => {
      const feedRef = db.collection('users').doc(uid).collection('feeds').doc(documentID);
      batch.set(feedRef,{roomID:roomID,documentID:documentID,createdAt:createdAt,uid:moderatorUid});
    });
    await batch.commit();
  };


});
