
const functions = require('firebase-functions')
const admin = require('firebase-admin')
admin.initializeApp(functions.config().firebase)
const algoliasearch = require('algoliasearch')
const ALGOLIA_ID = functions.config().algolia.app_id
const ALGOLIA_ADMIN_KEY = functions.config().algolia.api_key
const ALGOLIA_SEARCH_KEY = functions.config().algolia.search_key
const ALGOLIA_INDEX_NAME = 'Post_Like'
const client = algoliasearch(ALGOLIA_ID, ALGOLIA_ADMIN_KEY)
const db = admin.firestore();




exports.createIndex = functions.firestore.document('Room/{id}').onCreate((snap, context) => {
const data = snap.data();
data.objectID = context.params.id;
// algoliaのindexへ追加
const index = client.initIndex(ALGOLIA_INDEX_NAME)
return index.saveObject(data)
});


exports.updateIndex = functions.firestore.document('Room/{id}').onUpdate(async(change, context) => {
  const newData = change.after.data();
  // const beforeData = change.before.data();
  newData.objectID = change.after.id;
  const index = client.initIndex(ALGOLIA_INDEX_NAME)
  return index.saveObject(newData);
  });

exports.deleteIndex = functions.firestore.document('Room/{id}').onDelete((snap, context) => {
  const deletedData = snap.data();
  const objectID = context.params.id;
  console.log(objectID);
  const index = client.initIndex(ALGOLIA_INDEX_NAME)
  return index.deleteObject(objectID);
});




//ルームプロフィールを変更
exports.updateRoomDetail = functions.firestore.document('Room/{id}').onUpdate(async(change, context) => {


  const newData = change.after.data();
  const beforeData = change.before.data();
  const docName = beforeData.docName;
  const limit = 1;
  let batch = db.batch;
  const arrayChunk = <T extends any[]>(array: T, size: number): T[] =>
  array.reduce(
    (newarr, _, i) =>
      i % size ? newarr : [ ...newarr, array.slice(i, i + size)],
    []
  )

  if ((newData.roomName != beforeData.roomName) || (newData.roomImage != beforeData.roomImage)) {


    const users = await db.collection('Room').doc(docName).collection('roomMateList').get();

    console.log(users.docs);

    for(const chunkedUser of arrayChunk(users,2)){
      console.log('skkskskssksksks',chunkedUser);
    };

    // if (users.empty) {
    // console.log('No matching documents.');
    // return;
    // }
    // users.forEach(async doc => {
    //   console.log(doc.data().uid);
    // });



  }else{
    console.log('リターン');
    return;
  }
});


//自分のプロフィールを変更
exports.updateUser = functions.firestore.document('contents/{contentsID}/roomDetail/{roomDetailID}').onUpdate(async(change, context) => {

      const newValue = change.after.data();
      const beforeValue = change.before.data();


      if ((newValue.userName != beforeValue.userName) || (newValue.userImage != beforeValue.userImage)) {

        const docName = newValue.docName;
        console.log(docName);

        const uid2 = newValue.uid;
        console.log(uid2);

        const userRef = await db
        .collection('Room')
        .doc(docName).collection('Contents').where('uid','==',uid2)

        const snapshot = await userRef.get();
        if (snapshot.empty) {
        console.log('No matching documents.');
        return;
        }
        snapshot.forEach(async doc => {
          console.log(doc.data().docName);
          const updateName = await db.collection('Room').doc(docName).collection('Contents').doc(doc.data().docName).update({
            userName: newValue.userName,
            userImage: newValue.userImage
          });
        });


        const commentRef = await db.collection('contents').doc(uid2).collection('comment').where('roomDoc','==',docName)
        const snapshot2 = await commentRef.get();
        if (snapshot2.empty) {
          return;
        }
        snapshot2.forEach(async doc => {
          const updateCommentUserInfo = await db.collection('Room').doc(docName).collection('Contents').doc(doc.data().contentDoc)
          .collection('Comment').doc(doc.data().docName).update({
            userName: newValue.userName,
            userImage: newValue.userImage
          });
        });
        return true;

      }else{
        console.log('リターン');
        return;
      }


    });
