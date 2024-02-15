package top.plusalpha.rolling_geofence

import android.Manifest
import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.annotation.RequiresApi
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

const val LOG_TAG = "Geofence"

const val FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE = 1000
const val BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE = 2000
const val LOCATION_SETTING_REQUEST_CODE = 3000
const val START_SINGLE_LOCATION_REQUEST_CODE = 4000

const val LOCATION_PRIORITY = Priority.PRIORITY_HIGH_ACCURACY
const val GEOFENCE_RADIUS = 350.0f

const val GEOFENCE_PENDING_INTENT_REQUEST_CODE = 2345

class RollingGeofencePlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener, PluginRegistry.ActivityResultListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private var applicationContext: Context? = null
    private var geofencingClient: GeofencingClient? = null
    private var fusedLocationClient: FusedLocationProviderClient? = null

    private val geofenceList = mutableListOf<Geofence>()

    private lateinit var geofencePendingIntent: PendingIntent

    private var binding: ActivityPluginBinding? = null

    private var resultCallbackMap = HashMap<Int, Result>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "rolling_geofence")
        channel.setMethodCallHandler(this)

        applicationContext = flutterPluginBinding.applicationContext
        fusedLocationClient =
            LocationServices.getFusedLocationProviderClient(flutterPluginBinding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // 초기화의 역순으로 리셋
        fusedLocationClient = null
        applicationContext = null

        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            // Android 플러그인의 버전을 반환한다.
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }

            // 포그라운드 위치 조회 권한의 상태를 조회한다.
            "checkFgPermission" -> {
                if (applicationContext == null) {
                    result.error("ApplicationContextNull", null, null)
                    return
                }

                result.success(checkFgPermission(applicationContext!!) == PackageManager.PERMISSION_GRANTED)
            }

            // 백그라운드 위치 조회 권한의 상태를 조회한다.
            "checkBgPermission" -> {
                if (applicationContext == null) {
                    result.error("ApplicationContextNull", null, null)
                    return
                }

                result.success(checkBgPermission(applicationContext!!) == PackageManager.PERMISSION_GRANTED)
            }

            // 포그라운드 위치 조회 권한을 요청하기 전 사용자에게 상세한 설명을 해야 한다면 true
            // 아니라면 false가 반환된다.
            "shouldShowFgRationale" -> {
                result.success(shouldShowFgRationale())
            }

            // 백그라운드 위치 조회 권한을 요청하기 전 사용자에게 상세한 설명을 해야 한다면 true
            // 아니라면 false가 반환된다.
            "shouldShowBgRationale" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    result.success(shouldShowBgRationale())
                } else {
                    result.error(
                        "AndroidVersionTooLow",
                        "checkBackgroundLocationRationale: Not supported in this Android. At least Q required.",
                        null
                    )
                }
            }

            // 지오펜스 하나를 새로 등록 "예약"한다.
            // 여러 개의 지오펜스를 모아 등록하기 위해 예약하는 것이다.
            // 예약된 지오펜스를 모두 등록하기 위해서는 "createGeofencingClient" 메소드 호출이 필요하다.
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

            // 지오펜싱 클라이언트를 생성한다.
            // 생성 직후 기존에 등록된 모든 지오펜스는 삭제되고,
            // "registerGeofence"로 예약한 모든 지오펜스를 실제로 등록한다.
            // 실제로 등록된 후 예약된 지오펜스 항목은 삭제된다.
            "createGeofencingClient" -> {
                if (applicationContext == null) {
                    result.error("ApplicationContextNull", null, null)
                    return
                }

                // result는 함수 내에서 비동기적으로 처리한다.
                createGeofencingClient(applicationContext!!, result)
            }

            "requestLocationSetting" -> {
                requestLocationSetting(binding!!.activity, result)
            }

            "requestLocationPermission" -> {
                // result는 함수 내에서 비동기적으로 처리한다.
                requestLocationPermission(binding!!, result)
            }


            "requestBackgroundLocationPermission" -> {
                // result는 함수 내에서 비동기적으로 처리한다.
                requestBackgroundLocationPermission(result)
            }

            "startSingleLocationRequest" -> {
                if (applicationContext == null) {
                    result.error("ApplicationContextNull", null, null)
                    return
                }

                // result는 함수 내에서 비동기적으로 처리한다.
                startSingleLocationRequest(applicationContext!!, result)
            }

            "checkLocationPermission" -> {
                if (checkFgPermission(applicationContext!!) == PackageManager.PERMISSION_GRANTED) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        if (checkBgPermission(applicationContext!!) == PackageManager.PERMISSION_GRANTED) {
                            result.success("OK")
                        } else {
                            result.success("NoBackgroundLocationPermission")
                        }
                    } else {
                        result.success("OK")
                    }
                } else {
                    result.success("NoForegroundLocationPermission")
                }
            }

            "requestBatteryOptimizationPermission" -> {
                if (applicationContext == null) {
                    result.error("ApplicationContextNull", null, null)
                    return
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    requestBatteryOptimizationPermission(applicationContext!!, result)
                }
            }

            "isIgnoringBatteryOptimizations" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    isIgnoringBatteryOptimizations(applicationContext!!, result)
                } else {
                    result.success("OK")
                }
            }

            "openApplicationDetailsSettings" -> {
                if (applicationContext == null) {
                    result.error("ApplicationContextNull", null, null)
                    return
                }
                openApplicationDetailsSettings(applicationContext!!)
                result.success("OK")
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun isIgnoringBatteryOptimizations(context: Context, result: Result) {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager

        if (pm.isIgnoringBatteryOptimizations(context.packageName)) {
            result.success("OK")
        } else {
            result.success("Optimized")
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
                    GEOFENCE_RADIUS,
                )

                // Set the expiration duration of the geofence. This geofence gets automatically
                // removed after this period of time.
                .setExpirationDuration(NEVER_EXPIRE).setLoiteringDelay(5000)

                // Set the transition types of interest. Alerts are only generated for these
                // transition. We track entry and exit transitions in this sample.
                .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT or Geofence.GEOFENCE_TRANSITION_DWELL)
                .setNotificationResponsiveness(5000)

                // Create the geofence.
                .build()
        )


    }

    private fun getGeofencingRequest(): GeofencingRequest {
        // geofenceList가 비어 있으면 GeofencingRequest 만들지 못하고 예외 발생하니 주의

        return GeofencingRequest.Builder().apply {
            // 지오펜스가 추가될 때 ENTER 이벤트 트리거할지 말지인데,
            // iOS는 이런 기능이 없다... Android도 쓰지 말자.
            //setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            addGeofences(geofenceList)
        }.build()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding

        binding.addRequestPermissionsResultListener(this)
        binding.addActivityResultListener(this)
    }

    private fun requestLocationSetting(activity: Activity, result: Result) {
        val locationRequest = buildSingleLocationRequest()

        val builder = LocationSettingsRequest.Builder().addLocationRequest(locationRequest)

        val client: SettingsClient = LocationServices.getSettingsClient(activity)
        val task: Task<LocationSettingsResponse> = client.checkLocationSettings(builder.build())

        task.addOnSuccessListener {
            result.success("OK")
        }

        task.addOnFailureListener(fun(exception: java.lang.Exception) {
            if (exception is ResolvableApiException) {
                try {
                    resultCallbackMap[LOCATION_SETTING_REQUEST_CODE] = result

                    exception.startResolutionForResult(
                        activity, LOCATION_SETTING_REQUEST_CODE
                    )

                } catch (e: Exception) {
                    Log.e(LOG_TAG, e.toString())

                    result.error(
                        "RequestLocationSettingFailed",
                        "requestLocationSetting: exception 1",
                        e
                    )
                }

                return
            }

            result.error(
                "RequestLocationSettingFailed",
                "requestLocationSetting: exception 2",
                exception
            )
        })
    }

    private fun buildSingleLocationRequest() =
        LocationRequest.Builder(LOCATION_PRIORITY, 60 * 1000)
            .setMinUpdateDistanceMeters(GEOFENCE_RADIUS).setMaxUpdates(1).build()

    private fun requestLocationPermission(binding: ActivityPluginBinding, result: Result) {
        when {
            checkFgPermission(binding.activity.applicationContext) == PackageManager.PERMISSION_GRANTED -> {
                // 권한 허용된 상태 굿!
                result.success("OK")
            }

            shouldShowFgRationale() -> {
                // 이전의 권한 요청을 사용자가 명시적으로 거부했다. ('허용 안함' 선택)
                // 권한 허용이 필요한 이유에 대해 상세히 안내해야만 한다.
                // 그리고 다시 권한 허용 요청을 해야한다. (마지막 기회)

                /*result.error(
                    "LocationPermissionActivelyRefused",
                    "The user actively refused to allow location permission",
                    ""
                )

                openApplicationDetailsSettings(binding)*/

                resultCallbackMap[FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE] = result

                requestPermissions(
                    binding.activity, arrayOf(
                        Manifest.permission.ACCESS_FINE_LOCATION,
                    ), FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE
                )
            }

            else -> {
                // 권한 허용되지 않은 상태이고, 직접 허용을 요청할 수 있는 단계이다.
                // 요청하자!

                resultCallbackMap[FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE] = result

                requestPermissions(
                    binding.activity, arrayOf(
                        Manifest.permission.ACCESS_FINE_LOCATION,
                    ), FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE
                )
            }
        }
    }

    private fun checkFgPermission(context: Context) =
        ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        )

    private fun checkBgPermission(context: Context) =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(
                context, Manifest.permission.ACCESS_BACKGROUND_LOCATION
            )
        } else {
            true
        }

    // Android OS 레벨의 앱 별 App info 페이지를 열어준다.
    private fun openApplicationDetailsSettings(context: Context) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        val uri = Uri.fromParts("package", context.packageName, null)
        intent.data = uri
        intent.addFlags(FLAG_ACTIVITY_NEW_TASK)
        startActivity(context, intent, null)
    }

    private fun createGeofencingClient(context: Context, result: Result) {
        // You can use the API that requires the permission.
        geofencingClient = LocationServices.getGeofencingClient(context)

        val intent = Intent(context, GeofenceBroadcastReceiver::class.java)
        // We use FLAG_UPDATE_CURRENT so that we get the same pending intent back when calling
        // addGeofences() and removeGeofences().
        geofencePendingIntent = PendingIntent.getBroadcast(
            context,
            GEOFENCE_PENDING_INTENT_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )

        geofencingClient!!.removeGeofences(geofencePendingIntent).run {
            addOnSuccessListener {
                if (geofenceList.isNotEmpty()) {

                    geofencingClient!!.addGeofences(getGeofencingRequest(), geofencePendingIntent)
                        .run {
                            addOnSuccessListener {
                                // Geofences added
                                // ...
                                Log.d(LOG_TAG, "Add $it")
                                result.success("OK")
                            }
                            addOnFailureListener { exception ->
                                // Failed to add geofences
                                Log.d(LOG_TAG, "Add FAILED!!! $it")
                                result.error(
                                    "AddGeofencesFailed",
                                    "createGeofencingClient: addGeofences() failed with an exception",
                                    exception
                                )
                            }
                        }

                    geofenceList.clear()
                } else {
                    result.success("OK")
                }
            }
            addOnFailureListener { exception ->
                result.error(
                    "RemoveGeofencesFailed",
                    "createGeofencingClient: removeGeofences() failed with an exception",
                    exception
                )
            }
        }
    }

    private fun startSingleLocationRequest(context: Context, result: Result) {
        if (fusedLocationClient == null) {
            Log.e(LOG_TAG, "Fused location client is not ready")
            result.error("FusedLocationClientNotReady", null, null)
            return
        }

        // 현재 위치를 딱 한번만 조회해서 result로 반환
        val locationRequest = buildSingleLocationRequest()
        val builder = LocationSettingsRequest.Builder().addLocationRequest(locationRequest)
        val client: SettingsClient = LocationServices.getSettingsClient(context)
        val task: Task<LocationSettingsResponse> = client.checkLocationSettings(builder.build())
        task.addOnSuccessListener { locationSettingsResponse ->
            // All location settings are satisfied. The client can initialize
            // location requests here.
            // ...
            Log.i("Location", locationSettingsResponse.toString())

            fusedLocationClient!!.requestLocationUpdates(
                locationRequest, object : LocationCallback() {
                    override fun onLocationResult(locationResult: LocationResult) {
                        val doubleArrList = ArrayList<Double>()
                        for (it in locationResult.locations) {
                            doubleArrList.add(it.latitude)
                            doubleArrList.add(it.longitude)
                        }
                        result.success(doubleArrList)
                        //result.success(locationResult.locations.joinToString { it.toString() })
                    }
                }, Looper.getMainLooper()
            )

            // 여기서 result 설정하지 말고 singleLocationCallback에서 결과 지정한다.
            //result.success("OK")
        }

        task.addOnFailureListener(fun(exception: java.lang.Exception) {
            // 유저가 인터랙션이 필요해서 실패했다면(즉, 유저 인터랙션으로 실패를 해결할 수 있으면)
            // 그리고 binding이 있다면(즉, 앱이 전면에 있는 상태라면)
            // 해결한다.
            if (binding != null) {
                if (exception is ResolvableApiException) {
                    // Location settings are not satisfied, but this can be fixed
                    // by showing the user a dialog.
                    try {
                        // result 처리는 onActivityResult()에서 비동기적으로 처리된다.

                        resultCallbackMap[START_SINGLE_LOCATION_REQUEST_CODE] = result

                        // Show the dialog by calling startResolutionForResult(),
                        // and check the result in onActivityResult().
                        exception.startResolutionForResult(
                            binding!!.activity, START_SINGLE_LOCATION_REQUEST_CODE
                        )
                    } catch (e: Exception) {
                        Log.e(LOG_TAG, e.toString())

                        result.error(
                            "CheckLocationSettingsFailed",
                            "startSingleLocationRequest: startResolutionForResult() failed with an exception",
                            exception
                        )
                    }

                    return
                }
            }

            // 에러 확정!
            result.error(
                "CheckLocationSettingsFailed",
                "startSingleLocationRequest: checkLocationSettings() failed with an exception",
                exception
            )
        })
    }

    override fun onDetachedFromActivityForConfigChanges() {
        TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onDetachedFromActivity() {
        if (binding != null) {
            binding!!.removeActivityResultListener(this)
            binding!!.removeRequestPermissionsResultListener(this)
            binding = null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ): Boolean {
        when (requestCode) {
            // 위치 권한 설정 결과
            FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE -> {
                if (grantResults.isNotEmpty() && grantResults.all { it == 0 }) {

                    resultCallbackMap[FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE]?.success("LocationPermissionAllowed")
                } else {

                    resultCallbackMap[FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE]?.success("LocationPermissionDenied")
                }
                resultCallbackMap.remove(FOREGROUND_LOCATION_PERMISSION_REQUEST_CODE)
            }
            // 백그라운드 위치 권한 설정 결과
            BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE -> {
                if (grantResults.isNotEmpty() && grantResults.all { it == 0 }) {

                    resultCallbackMap[BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE]?.success("BackgroundLocationPermissionAllowed")
                } else {

                    resultCallbackMap[BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE]?.success("BackgroundLocationPermissionDenied")
                }

                resultCallbackMap.remove(BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE)
            }

            else -> {
                Log.e(LOG_TAG, "onRequestPermissionsResult: Unknown request code '${requestCode}'.")
            }
        }

        return true
    }

    private fun requestBackgroundLocationPermission(result: Result) {
        if (binding == null) {
            result.error(
                "ContextNull",
                "requestBackgroundLocationPermission: Context is null",
                null
            )
            return
        }

        val context = binding!!.activity.applicationContext
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            when {
                checkBgPermission(context) == PackageManager.PERMISSION_GRANTED -> {
                    // 권한이 부여되어 있다. 상황 종료.
                    result.success("OK")
                }

                shouldShowBgRationale() -> {
                    // 권한 부여 요청을 하기 전에 그 권한이 왜 필요한지 사용자에게 설명한다.
                    // 그리고 다음 화면에서 '항상 허용'에 체크할 것을 안내한다.
                    // 그 이후, 다음 화면으로 보낸다.

                    resultCallbackMap[BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE] = result
                    requestPermissions(
                        binding!!.activity, arrayOf(
                            Manifest.permission.ACCESS_BACKGROUND_LOCATION,
                        ), BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE
                    )
                }

                else -> {
                    // 사용자가 권한 설정을 거절했거나 잘못 설정했다.
                    // 알아서 하라고 할 수 밖에...?
                    result.success("BackgroundLocationPermissionActivelyDenied")
                }
            }
        } else {
            // 버전이 낮아서 백그라운드 권한을 따로 요청할 필요가 없겠지...?
            // 성공한 것으로 취급한다.
            result.success("OK")
        }
    }

    private fun shouldShowFgRationale() =
        ActivityCompat.shouldShowRequestPermissionRationale(
            binding!!.activity, Manifest.permission.ACCESS_FINE_LOCATION
        )

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun shouldShowBgRationale() =
        ActivityCompat.shouldShowRequestPermissionRationale(
            binding!!.activity, Manifest.permission.ACCESS_BACKGROUND_LOCATION
        )

    @RequiresApi(Build.VERSION_CODES.M)
    private fun requestBatteryOptimizationPermission(
        context: Context,
        result: Result
    ) {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager

        if (pm.isIgnoringBatteryOptimizations(context.packageName)) {
            result.success("OK")
        } else {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.data = Uri.fromParts("package", context.packageName, null)
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK)
            startActivity(context, intent, null)
            result.success("Requested")
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        Log.i(LOG_TAG, "onActivityResult: request code=$requestCode, resultCode=$resultCode")
        when (requestCode) {
            LOCATION_SETTING_REQUEST_CODE -> {
                Log.i(LOG_TAG, "LOCATION_SETTING_REQUEST_CODE result received.")
            }

            START_SINGLE_LOCATION_REQUEST_CODE -> {
                // HIGH_ACCURACY로 위치 정보 조회 시 WiFi를 써야만 한다.
                // 그런데 WiFi를 쓸 수 없도록 설정되어 있다면 쓸 수 있도록 유저에게 요청 팝업이 뜬다.
                // 팝업에서 어떻게 응답했느냐에 따라 resultCode가 다르다.
                Log.i(LOG_TAG, "START_SINGLE_LOCATION_REQUEST_CODE result received.")

                when (resultCode) {
                    0 -> {
                        // 거절했다... 허어...
                        resultCallbackMap[START_SINGLE_LOCATION_REQUEST_CODE]?.success("WiFiPermissionRequiredForAccuracyDenied")
                    }

                    -1 -> {
                        // 권한을 부여했다. 처음부터 다시 시작하자. (이제 되겠지)
                        startSingleLocationRequest(
                            applicationContext!!,
                            resultCallbackMap[START_SINGLE_LOCATION_REQUEST_CODE]!!
                        )
                    }

                    else -> {
                        resultCallbackMap[START_SINGLE_LOCATION_REQUEST_CODE]?.error(
                            "UnknownResult",
                            "Unknown result code received: $resultCode",
                            null
                        )
                    }
                }

                resultCallbackMap.remove(START_SINGLE_LOCATION_REQUEST_CODE)
            }

            else -> {
                Log.e(LOG_TAG, "onActivityResult: Unknown request code '${requestCode}'.")
            }
        }
        return true
    }
}
