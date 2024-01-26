package top.plusalpha.rolling_geofence

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingEvent
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent!!)

        if (geofencingEvent == null) {
            Log.e("Geofence", "geofencingEvent null")
            return
        } else if (geofencingEvent.hasError()) {
            val errorMessage = GeofenceStatusCodes
                .getStatusCodeString(geofencingEvent.errorCode)
            Log.e("Geofence", errorMessage)
            return
        }

        // Get the transition type.
        val geofenceTransition = geofencingEvent.geofenceTransition

        // Test that the reported transition was of interest.
        if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER || geofenceTransition == Geofence.GEOFENCE_TRANSITION_EXIT || geofenceTransition == Geofence.GEOFENCE_TRANSITION_DWELL) {

            Log.i("Geofencing", "Transition type: $geofenceTransition begin")
            // Get the geofences that were triggered. A single event can trigger
            // multiple geofences.
            val triggeringGeofences = geofencingEvent.triggeringGeofences
            if (triggeringGeofences != null) {
                triggeringGeofences.forEach {
                    Log.i("Geofencing", it.toString())
                }
                //Log.i("Geofencing", triggeringGeofences.map { it.toString() }.joinToString { "***" })

            } else {
                Log.i("Geofencing", "triggering geofences empty")
            }
            Log.i("Geofencing", "Transition type: $geofenceTransition end")

            val engine = FlutterEngine(context!!)
            val geofenceTransitionStr = when (geofenceTransition) {
                Geofence.GEOFENCE_TRANSITION_ENTER -> "enter"
                Geofence.GEOFENCE_TRANSITION_EXIT -> "exit"
                Geofence.GEOFENCE_TRANSITION_DWELL -> "dwell"
                else -> "unknown"
            }
            val requestIdList = triggeringGeofences?.map { it.requestId }.orEmpty()
            val args = mutableListOf(geofenceTransitionStr)
            args.addAll(requestIdList)




            // if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_EXIT) {
            //     val geofenceList = mutableListOf<Geofence>()
            //     geofenceList.add(
            //         Geofence.Builder()
            //             .setRequestId("test123")
            //             .setCircularRegion(
            //                 37.7132,
            //                 126.8901,
            //                 350.0f,
            //                 )
            //             .setExpirationDuration(Geofence.NEVER_EXPIRE)
            //             .setLoiteringDelay(5000)
            //             .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT or Geofence.GEOFENCE_TRANSITION_DWELL)
            //             .setNotificationResponsiveness(5000)
            //             .build())
            //     val geofencePendingIntent = PendingIntent.getBroadcast(context, 2345, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
            //     val gClient = LocationServices.getGeofencingClient(context)
            //     gClient.removeGeofences(geofencePendingIntent)
            //     gClient.addGeofences(GeofencingRequest.Builder().apply {
            //         setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            //         addGeofences(geofenceList)
            //     }.build(), geofencePendingIntent).run {
            //         addOnSuccessListener {
            //             //
            //         }
            //         addOnFailureListener {
            //             //
            //         }
            //     }
            // }




            engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint("lib/main.dart", "onGeofenceEvent"), args)
        } else {
            // Log the error.
            Log.e("Geofencing", "unknown transition event")
        }
    }
}
