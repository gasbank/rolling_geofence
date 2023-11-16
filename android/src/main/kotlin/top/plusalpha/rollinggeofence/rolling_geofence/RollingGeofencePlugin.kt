package top.plusalpha.rollinggeofence.rolling_geofence

import android.Manifest
import android.app.PendingIntent
import android.content.Intent
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.ActivityCompat.requestPermissions
import androidx.core.content.ContextCompat
import androidx.core.content.ContextCompat.startActivity
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.Geofence.NEVER_EXPIRE
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry


class RollingGeofencePlugin: FlutterPlugin, MethodCallHandler, ActivityAware,
  PluginRegistry.RequestPermissionsResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private lateinit var geofencingClient: GeofencingClient
  private val geofenceList = mutableListOf<Geofence>()

  private lateinit var geofencePendingIntent: PendingIntent;

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "rolling_geofence")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
        "getPlatformVersion" -> {
          result.success("Android 으히히히 ${android.os.Build.VERSION.RELEASE}")
        }
        "registerGeofences" -> {
          registerGeofences()
          result.success("OK")
        }
        else -> {
          result.notImplemented()
        }
    }
  }

  fun registerGeofences() {

    geofenceList.add(
      Geofence.Builder()
      // Set the request ID of the geofence. This is a string to identify this
      // geofence.
      .setRequestId("office")

      // Set the circular region of this geofence.
      .setCircularRegion(
        37.517636,
        126.931994,
        200.0f,
      )

      // Set the expiration duration of the geofence. This geofence gets automatically
      // removed after this period of time.
      .setExpirationDuration(NEVER_EXPIRE)

      // Set the transition types of interest. Alerts are only generated for these
      // transition. We track entry and exit transitions in this sample.
      .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)

      // Create the geofence.
      .build())


  }

  private fun getGeofencingRequest(): GeofencingRequest {
    return GeofencingRequest.Builder().apply {
      setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
      addGeofences(geofenceList)
    }.build()
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    binding.addRequestPermissionsResultListener(this);

    when {
      ContextCompat.checkSelfPermission(
        binding.activity.applicationContext,
        Manifest.permission.ACCESS_FINE_LOCATION
      ) == PackageManager.PERMISSION_GRANTED -> {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          when {
            ContextCompat.checkSelfPermission(
              binding.activity.applicationContext,
              Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED -> {
              createGeofencingClient(binding)
            }

            ActivityCompat.shouldShowRequestPermissionRationale(
              binding.activity, Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) -> {
              // In an educational UI, explain to the user why your app requires this
              // permission for a specific feature to behave as expected, and what
              // features are disabled if it's declined. In this UI, include a
              // "cancel" or "no thanks" button that lets the user continue
              // using your app without granting the permission.
              openApplicationDetailsSettings(binding)
            }

            else -> {
              // You can directly ask for the permission.

              requestPermissions(
                binding.activity,
                arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                1985
              )

            }
          }
        } else {
          createGeofencingClient(binding)
        }
      }
      ActivityCompat.shouldShowRequestPermissionRationale(
        binding.activity, Manifest.permission.ACCESS_FINE_LOCATION) -> {
        // In an educational UI, explain to the user why your app requires this
        // permission for a specific feature to behave as expected, and what
        // features are disabled if it's declined. In this UI, include a
        // "cancel" or "no thanks" button that lets the user continue
        // using your app without granting the permission.
        openApplicationDetailsSettings(binding)
      }
      else -> {
        // You can directly ask for the permission.
        requestPermissions(binding.activity,
          arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
          1985)
      }
    }


  }

  private fun openApplicationDetailsSettings(binding: ActivityPluginBinding) {
    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
    val uri = Uri.fromParts("package", binding.activity.packageName, null)
    intent.data = uri
    intent.addFlags(FLAG_ACTIVITY_NEW_TASK)
    startActivity(binding.activity.applicationContext, intent, null)
  }

  private fun createGeofencingClient(binding: ActivityPluginBinding) {
    // You can use the API that requires the permission.
    geofencingClient = LocationServices.getGeofencingClient(binding.activity)

    registerGeofences();

    val intent = Intent(binding.activity, GeofenceBroadcastReceiver::class.java)
    // We use FLAG_UPDATE_CURRENT so that we get the same pending intent back when calling
    // addGeofences() and removeGeofences().
    geofencePendingIntent = PendingIntent.getBroadcast(
      binding.activity.applicationContext,
      0,
      intent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
    )

    geofencingClient.addGeofences(getGeofencingRequest(), geofencePendingIntent).run {
      addOnSuccessListener {
        // Geofences added
        // ...
        Log.d("Geofence", "Add $it")
      }
      addOnFailureListener {
        // Failed to add geofences
        Log.d("Geofence", "Add FAILED!!! $it")
      }
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {
    TODO("Not yet implemented")
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    TODO("Not yet implemented")
  }

  override fun onDetachedFromActivity() {
    TODO("Not yet implemented")
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {
    TODO("Not yet implemented")
  }
}
