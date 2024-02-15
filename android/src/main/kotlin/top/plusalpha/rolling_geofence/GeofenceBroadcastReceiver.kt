package top.plusalpha.rolling_geofence

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent!!)

        if (geofencingEvent == null) {
            Log.e(LOG_TAG, "geofencingEvent null")
            return
        } else if (geofencingEvent.hasError()) {
            val errorMessage = GeofenceStatusCodes
                .getStatusCodeString(geofencingEvent.errorCode)
            Log.e(LOG_TAG, errorMessage)
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
                    Log.i(LOG_TAG, it.toString())
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

            // args의 첫 번째는 transition type, 두 번째부터 지오펜스 이름이 들어간다.
            val args = mutableListOf(geofenceTransitionStr)
            args.addAll(requestIdList)

            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(
                    "lib/main.dart",
                    "onGeofenceEvent"
                ), args
            )
        } else {
            // Log the error.
            Log.e(LOG_TAG, "unknown transition event")
        }
    }
}
