import unittest
import sys


class DecordTest(unittest.TestCase):
    """ Simple functionality tests. """

    def test_import(self):
        """ Test that the cv2 module can be imported. """
        import decord

    def test_video_capture(self):

        import decord as dc
        cap = dc.VideoReader("SampleVideo_1280x720_1mb.mp4")
        self.assertTrue(len(cap))
