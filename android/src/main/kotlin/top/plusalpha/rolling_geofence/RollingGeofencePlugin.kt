package top.plusalpha.rolling_geofence

import android.Manifest
import android.app.PendingIntent
import android.content.Intent
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK
import android.content.IntentSender
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.ActivityCompat.requestPermissions
import androidx.core.content.ContextCompat
import androidx.core.content.ContextCompat.startActivity
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.Geofence.NEVER_EXPIRE
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.LocationSettingsRequest
import com.google.android.gms.location.LocationSettingsResponse
import com.google.android.gms.location.Priority
import com.google.android.gms.location.SettingsClient
import com.google.android.gms.tasks.Task
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

const val FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE = 1000
const val BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE = 2000

class RollingGeofencePlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private lateinit var geofencingClient: GeofencingClient
    private val geofenceList = mutableListOf<Geofence>()

    private lateinit var geofencePendingIntent: PendingIntent;

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback

    private var binding: ActivityPluginBinding? = null

    private var resultCallbackMap = HashMap<Int, Result>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "rolling_geofence")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            "registerGeofence" -> {
                if (call.argument<String>("name") == null || call.argument<Double>("latitude") == null || call.argument<Double>(
                        "longitude"
                    ) == null
                ) {
                    result.error("type mismatch", null, null)
                }
                registerGeofence(
                    call.argument<String>("name")!!,
                    call.argument<Double>("latitude")!!,
                    call.argument<Double>("longitude")!!
                )
                result.success("OK")
            }

            "updateGeofence" -> {
                updateGeofence()
            }

            "clearGeofence" -> {
                clearGeofence()
            }

            "createGeofencingClient" -> {
                createGeofencingClient(binding!!)
                result.success("OK")
            }

            "requestLocationPermission" -> {
                // result는 함수 내에서 비동기적으로 처리한다.
                requestLocationPermission(binding!!, result)
            }

            "requestBackgroundLocationPermission" -> {
                // result는 함수 내에서 비동기적으로 처리한다.
                requestBackgroundLocationPermission(result)
            }

            "startLocationRequest" -> {
                startLocationRequest(binding!!)
                result.success("OK")
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun registerGeofence(name: String, latitude: Double, longitude: Double) {

        geofenceList.add(
            Geofence.Builder()
                // Set the request ID of the geofence. This is a string to identify this
                // geofence.
                .setRequestId(name)

                // Set the circular region of this geofence.
                .setCircularRegion(
                    latitude,
                    longitude,
                    350.0f,
                )

                // Set the expiration duration of the geofence. This geofence gets automatically
                // removed after this period of time.
                .setExpirationDuration(NEVER_EXPIRE)
                .setLoiteringDelay(5000)

                // Set the transition types of interest. Alerts are only generated for these
                // transition. We track entry and exit transitions in this sample.
                .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT or Geofence.GEOFENCE_TRANSITION_DWELL)
                .setNotificationResponsiveness(5000)

                // Create the geofence.
                .build()
        )


    }

    private fun updateGeofence() {
        geofencingClient.addGeofences(getGeofencingRequest(), geofencePendingIntent).run {
            addOnSuccessListener {
                // Geofences added
                // ...
                Log.d("Geofence", "Add $it")
                callSuccessCallback(2)
            }
            addOnFailureListener {
                // Failed to add geofences
                Log.d("Geofence", "Add FAILED!!! $it")
                callErrorCallback(3)
            }
        }
    }

    private fun clearGeofence() {
        geofenceList.clear()
        geofencingClient.removeGeofences(geofencePendingIntent)
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
        this.binding = binding

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(binding.activity)
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                for (location in locationResult.locations) {
                    Log.i("Location", location.toString())
                }
            }
        }
        binding.addRequestPermissionsResultListener(this);

//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
//            ContextCompat.checkSelfPermission(
//                binding.activity.applicationContext,
//                Manifest.permission.ACCESS_FINE_LOCATION
//            )
//
//            requestPermissions(
//                binding.activity,
//                arrayOf(
//                    Manifest.permission.ACCESS_FINE_LOCATION,
//                    Manifest.permission.ACCESS_BACKGROUND_LOCATION
//                ),
//                1985
//            )
//        } else {
//            requestPermissions(
//                binding.activity,
//                arrayOf(
//                    Manifest.permission.ACCESS_FINE_LOCATION,
//                ),
//                1985
//            )
//        }

        // 권한 요청 순서는 다음과 같이 한다.
        //
        // (1) Manifest.permission.ACCESS_FINE_LOCATION
        // (2) Manifest.permission.ACCESS_BACKGROUND_LOCATION
        //
        // 우선 (1)부터...
        //requestLocationPermission(binding)
    }

    private fun requestLocationPermission(binding: ActivityPluginBinding, result: Result) {
        when {
            ContextCompat.checkSelfPermission(
                binding.activity.applicationContext,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED -> {
                // 권한 허용된 상태이다. 다음 권한 요청한다.
                requestBackgroundLocationPermission(result)
            }

            ActivityCompat.shouldShowRequestPermissionRationale(
                binding.activity, Manifest.permission.ACCESS_FINE_LOCATION
            ) -> {
                // 유저가 권한 부여 요청을 명시적으로 거부했다.
                // 권한 허용이 필요한 이유에 대해 상세히 안내해야만 한다.

                result.error(
                    "LocationPermissionActivelyRefused",
                    "The user actively refused to allow location permission",
                    ""
                )

                //openApplicationDetailsSettings(binding)
            }

            else -> {
                // 권한 허용되지 않은 상태이고, 직접 허용을 요청할 수 있는 단계이다.
                // 요청하자!

                resultCallbackMap[FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE] = result

                requestPermissions(
                    binding.activity,
                    arrayOf(
                        Manifest.permission.ACCESS_COARSE_LOCATION,
                        Manifest.permission.ACCESS_FINE_LOCATION,
                    ),
                    FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE
                )
            }
        }
    }

    // Android OS 레벨의 앱 별 App info 페이지를 열어준다.
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

        val intent = Intent(binding.activity, GeofenceBroadcastReceiver::class.java)
        // We use FLAG_UPDATE_CURRENT so that we get the same pending intent back when calling
        // addGeofences() and removeGeofences().
        geofencePendingIntent = PendingIntent.getBroadcast(
            binding.activity.applicationContext,
            2345,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )

        geofencingClient.removeGeofences(geofencePendingIntent)

        geofencingClient.addGeofences(getGeofencingRequest(), geofencePendingIntent).run {
            addOnSuccessListener {
                // Geofences added
                // ...
                Log.d("Geofence", "Add $it")
                callSuccessCallback(2)
            }
            addOnFailureListener {
                // Failed to add geofences
                Log.d("Geofence", "Add FAILED!!! $it")
                callErrorCallback(3)
            }
        }
    }

    private fun startLocationRequest(binding: ActivityPluginBinding) {
        val locationRequest =
            LocationRequest.Builder(Priority.PRIORITY_BALANCED_POWER_ACCURACY, 60 * 1000)
                .setMinUpdateDistanceMeters(200.0f)
                .build()
        val builder = LocationSettingsRequest.Builder()
            .addLocationRequest(locationRequest)
        val client: SettingsClient = LocationServices.getSettingsClient(binding.activity)
        val task: Task<LocationSettingsResponse> = client.checkLocationSettings(builder.build())
        task.addOnSuccessListener { locationSettingsResponse ->
            // All location settings are satisfied. The client can initialize
            // location requests here.
            // ...
            Log.i("Location", locationSettingsResponse.toString())

            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )

            // Foreground 서비스 시작 (테스트)

//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                val serviceIntent = Intent(binding.activity, GeofenceForegroundService::class.java)
//                binding.activity.applicationContext.startForegroundService(serviceIntent)
//            }

            callSuccessCallback(1)
        }

        task.addOnFailureListener { exception ->
            if (exception is ResolvableApiException) {
                // Location settings are not satisfied, but this can be fixed
                // by showing the user a dialog.
                try {
                    // Show the dialog by calling startResolutionForResult(),
                    // and check the result in onActivityResult().
                    exception.startResolutionForResult(
                        binding.activity,
                        3000
                    )
                } catch (sendEx: IntentSender.SendIntentException) {
                    // Ignore the error.
                }
            }
            callErrorCallback(4)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onDetachedFromActivity() {
        //TODO("Not yet implemented")
        this.binding = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        when (requestCode) {
            // 위치 권한 설정 결과
            FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE -> {
                if (grantResults.all { it == 0 }) {
                    channel.invokeMethod("onLocationPermissionAllowed", null)

                    resultCallbackMap[FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE]?.success("LocationPermissionAllowed")
                } else {
                    //val args: Map<String?, Any?> = HashMap()
                    channel.invokeMethod("onLocationPermissionDenied", null)

                    resultCallbackMap[FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE]?.error(
                        "LocationPermissionDenied",
                        "The user cancelled/denied foreground location permission",
                        ""
                    )
                }
                resultCallbackMap.remove(FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE)
            }
            // 백그라운드 위치 권한 설정 결과
            BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE -> {
                if (grantResults.all { it == 0 }) {
                    channel.invokeMethod("onBackgroundLocationPermissionAllowed", null)

                    resultCallbackMap[BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE]?.success("BackgroundLocationPermissionAllowed")
                } else {
                    //val args: Map<String?, Any?> = HashMap()
                    channel.invokeMethod("onBackgroundLocationPermissionDenied", null)

                    resultCallbackMap[BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE]?.error(
                        "BackgroundLocationPermissionDenied",
                        "The user cancelled/denied background foreground location permission",
                        ""
                    )
                }

                resultCallbackMap.remove(BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE)
            }

            3000 -> {
                callErrorCallback(2)
            }
        }

        return true;
    }

    private fun requestBackgroundLocationPermission(result: Result) {
        val context = binding!!.activity.applicationContext
        when {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED -> {
                startLocationRequest(binding!!)
                result.success("OK")
            }

            ActivityCompat.shouldShowRequestPermissionRationale(
                binding!!.activity, Manifest.permission.ACCESS_FINE_LOCATION
            ) -> {
                // 유저가 권한 부여 요청을 명시적으로 거부했다.
                // 권한 허용이 필요한 이유에 대해 상세히 안내해야만 한다.

                result.error(
                    "BackgroundLocationPermissionActivelyRefused",
                    "The user actively refused to allow background location permission",
                    ""
                )

                //openApplicationDetailsSettings(binding!!)
            }

            ActivityCompat.shouldShowRequestPermissionRationale(
                binding!!.activity, Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) -> {
                // 유저가 권한 부여 요청을 명시적으로 거부했다.
                // 권한 허용이 필요한 이유에 대해 상세히 안내해야만 한다.

                result.error(
                    "BackgroundLocationPermissionActivelyRefused",
                    "The user actively refused to allow background location permission",
                    ""
                )

                //openApplicationDetailsSettings(binding!!)
            }

            else -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    resultCallbackMap[BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE] = result
                    requestPermissions(
                        binding!!.activity,
                        arrayOf(
                            Manifest.permission.ACCESS_BACKGROUND_LOCATION,
                        ),
                        BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE
                    )
                } else {
                    callErrorCallback(1)
                    result.error(
                        "BackgroundLocationFailedNotSupportedAndroidVersion",
                        "Android 10 or later version needed to use this function",
                        ""
                    )
                }
            }
        }
    }

    private fun callErrorCallback(code: Int) {
        val args: MutableMap<String?, Any?> = HashMap()
        args["code"] = code
        channel.invokeMethod("onError", args)
    }

    private fun callSuccessCallback(code: Int) {
        val args: MutableMap<String?, Any?> = HashMap()
        args["code"] = code
        channel.invokeMethod("onSuccess", args)
    }
}
