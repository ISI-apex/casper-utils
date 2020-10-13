#include <stdio.h>

#include <alps/libalps.h>
#include <alps/libalpslli.h>
#include <alps/alps_toolAssist.h>
#include <alps/libalpsutil.h>

#define ERROR(rc, func) \
	fprintf(stderr, "ERROR: %s: rc %d\n", func, rc)

int do_alps() {
	int ret;
	int alps_status = 0, apid = 0;
	size_t alps_count = 0;

	printf("sending alpslli request...\n");

	ret = alps_app_lli_put_request(ALPS_APP_LLI_ALPS_REQ_APID, NULL, 0);
	if (ALPS_APP_LLI_ALPS_STAT_OK != ret) {
		ERROR (ret, "alps_app_lli_put_simple_request()");
		return 1;
	}

	ret = alps_app_lli_get_response (&alps_status, &alps_count);
	if (ret < 0) {
		ERROR (ret, "alps_app_lli_get_response()");
		return 1;
	}

	ret = alps_app_lli_get_response_bytes (&apid, sizeof(apid));
	if (ret < 0) {
		ERROR (ret, "alps_app_lli_get_response_bytes()");
		return 1;
	}

	printf("status %d count %lu appdid %d\n",
			alps_status, alps_count, apid);

#if 0
	ret = alps_get_appinfo(apid, &app_info, &app_cmddetail, &app_places);
	if (-1 == ret)
		ERROR (ret, "alps_get_appinfo()");
#endif

	return 0;
}
