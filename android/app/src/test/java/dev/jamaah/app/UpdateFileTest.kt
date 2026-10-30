package dev.jamaah.app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class UpdateFileTest {
    @Test
    fun onlyUpdateShapeInstalls() {
        assertTrue(UpdateFile.nameOk("Jamaah-update.apk"))
        assertTrue(UpdateFile.nameOk("Jamaah-update-short.apk"))
        assertFalse("a directory part is not an update the app wrote", UpdateFile.nameOk("cache/Jamaah-update.apk"))
        assertFalse(UpdateFile.nameOk("Jamaah-1.0.5.apk"))
        assertFalse(UpdateFile.nameOk("update.apk"))
        assertFalse(UpdateFile.nameOk("Jamaah-update2.apk"))
        assertFalse(UpdateFile.nameOk(null))
    }

    @Test
    fun aMissingHashIsNotAPass() {
        assertTrue(UpdateFile.hashOk("23026ce8dc73a34bd3d38130489ae87af14c7665712c0589a56fd1982554aada"))
        assertTrue(UpdateFile.hashOk("23026CE8DC73A34BD3D38130489AE87AF14C7665712C0589A56FD1982554AADA"))
        assertFalse(UpdateFile.hashOk(null))
        assertFalse(UpdateFile.hashOk(""))
        assertFalse("63 hex is nearly a hash, and nearly is not", UpdateFile.hashOk("23026ce8dc73a34bd3d38130489ae87af14c7665712c0589a56fd1982554aa"))
        assertFalse(UpdateFile.hashOk("23026ce8dc73a34bd3d38130489ae87af14c7665712c0589a56fg1982554aada"))
    }
}
